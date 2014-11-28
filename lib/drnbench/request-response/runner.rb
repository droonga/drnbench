# Copyright (C) 2013-2014  Droonga Project
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "facter"
require "drnbench/client/http"
require "drnbench/client/http-droonga"
require "drnbench/request-response/result"
require "drnbench/request-response/request-pattern"

module Drnbench
  module RequestResponse
    class Runner
      attr_reader :n_clients, :result

      MESSAGE_EXIT     = "exit"
      MESSAGE_START    = "start"
      MESSAGE_COMPLETE = "complete"

      def initialize(n_clients, config)
        n_clients = 1 if n_clients.zero?
        @n_clients = n_clients
        @config = config

        abstract = RequestPattern::Abstract.new(@config.request_patterns, @config)
        @requests = abstract.requests.shuffle
      end

      def run
        process_requests
        @result
      end

      def pop_request
        @requests.pop
      end

      def push_result(result)
        @result << result
      end

      def empty?
        @requests.empty?
      end

      private
      def process_requests
        @result = Result.new(:n_clients => @n_clients,
                             :duration => @config.duration,
                             :n_fast_requests => @config.n_fast_requests,
                             :n_slow_requests => @config.n_slow_requests)

        setup_child_processes
        initiate_child_processes
        wait_for_given_duration
        kill_child_processes

        @result
      end

      def setup_child_processes
        @child_processes = []
        @total_n_clients = 0
        n_processes.times.each do |index|
          setup_child_process
        end
      end

      def setup_child_process
        n_clients = n_clients_per_process
        if @total_n_clients + n_clients > @n_clients
          n_clients = @n_clients - @total_n_clients
        end
        return if n_clients <= 0

        # Prepare request queue for child process at first
        # to reduce needless inter-process communications (IPC) while running!
        requests_queue = Queue.new
        @requests.slice!(0..n_requests_per_process).each do |request|
          requests_queue.push(request)
        end

        parent_read, child_write = IO.pipe
        child_read, parent_write = IO.pipe

        pid = fork do

          parent_write.close
          parent_read.close
          druby_uri = child_read.gets.chomp
          @parent = DRbObject.new_with_uri(druby_uri)

          @requests = requests_queue
          @result = []

          # Because continuous benchmark increases objects,
          # GC painflly slows down the process.
          GC.start
          GC.disable

          clients = setup_clients(n_clients)

          loop do
            message = child_read.gets
            if message and message.chomp == MESSAGE_EXIT
              clients.each(&:stop)
              # We also should reduce IPC for results.
              @result.each do |result|
                @parent.push_result(result)
              end
              child_write.puts(MESSAGE_COMPLETE)
              child_write.close
              exit!
            end
            sleep(3)
          end
        end
        @child_processes << {
          :pid    => pid,
          :input  => parent_read,
          :output => parent_write,
        }

        requests_queue = nil

        child_read.close
        child_write.close
      end

      def setup_clients(count)
        count.times.collect do |index|
          case @config.mode
          when :http
            client = HttpClient.new(:runner => self,
                                    :config => @config)
          when :http_droonga
            client = HttpDroongaClient.new(:runner => self,
                                           :config => @config)
          else
            raise ArgumentError.new("Unknown mode: #{@config.mode}")
          end
          client.run
          client
        end
      end

      def initiate_child_processes
        DRb.start_service("druby://localhost:0", self)
        @child_processes.each do |child|
          child[:output].puts(DRb.uri)
        end
      end

      ONE_MINUTE_IN_SECONDS = 60
      ONE_HOUR_IN_SECONDS = ONE_MINUTE_IN_SECONDS * 60

      def wait_for_given_duration
        start_time = Time.now
        last_message = ""
        loop do
          sleep 1
          elapsed_time = (Time.now - start_time).to_i
          break if elapsed_time >= @config.duration

          remaining_seconds  = @config.duration - elapsed_time
          remaining_hours    = (remaining_seconds / ONE_HOUR_IN_SECONDS).floor
          remaining_seconds -= remaining_hours * ONE_HOUR_IN_SECONDS
          remaining_minutes  = (remaining_seconds / ONE_MINUTE_IN_SECONDS).floor
          remaining_seconds -= remaining_minutes * ONE_MINUTE_IN_SECONDS
          remaining_time     = sprintf("%02i:%02i:%02i", remaining_hours, remaining_minutes, remaining_seconds)
          next_message = "#{remaining_time} remaining..."
          printf("%s", "#{" " * last_message.size}\r")
          printf("%s", "#{next_message}\r")
          last_message = next_message
        end
      end

      def kill_child_processes
        puts "Collecting results..."

        @child_processes.each do |child|
          child[:output].puts(MESSAGE_EXIT)
        end

        loop do
          @child_processes = @child_processes.reject do |child|
            message = child[:input].gets
            if message and message.chomp == MESSAGE_COMPLETE
              Process.detach(child[:pid])
              true
            else
              false
            end
          end
          break if @child_processes.empty?
        end
      end

      def n_processes
        [[@n_clients, 1].max, max_n_processes].min
      end

      def max_n_processes
        Facter["processorcount"].value.to_i
      end

      def n_clients_per_process
        (@n_clients.to_f / n_processes).ceil
      end

      def n_requests_per_process
        (@requests.size.to_f / n_processes).round
      end
    end
  end
end
