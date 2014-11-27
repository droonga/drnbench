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
        @requests_queue.pop
      end

      def push_result(result)
        @result << result
      end

      def empty?
        @requests_queue.empty?
      end

      private
      def process_requests
        @requests_queue = Queue.new
        @requests.each do |request|
          @requests_queue.push(request)
        end
        @result = Result.new(:n_clients => @n_clients,
                             :duration => @config.duration,
                             :n_slow_requests => @config.n_slow_requests)

        setup_child_processes
        initiate_child_processes
        wait_for_given_duration
        kill_child_processes

        @result
      end

      def setup_child_processes
        @child_process_pipes = []
        n_processes.times.each do |index|
          setup_child_process
        end
      end

      def setup_child_process
        parent_read, child_write = IO.pipe
        child_read, parent_write = IO.pipe
        @child_process_pipes << [parent_read, parent_write]

        # Prepare request queue for child process at first
        # to reduce needless inter-process communications (IPC) while running!
        child_process_requests_queue = Queue.new
        n_requests_per_process.times.each do |index|
          child_process_requests_queue.push(@requests_queue.pop)
        end

        fork do
          parent_write.close
          parent_read.close
          druby_uri = child_read.gets.chomp
          @parent = DRbObject.new_with_uri(druby_uri)

          @requests_queue = child_process_requests_queue
          @result = []

          clients = setup_clients(n_clients_per_process)

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
        @child_process_pipes.each do |input, output|
          output.puts(DRb.uri)
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
        @child_process_pipes.each do |input, output|
          output.puts(MESSAGE_EXIT)
        end

        loop do
          @child_process_pipes = @child_process_pipes.reject do |input, output|
            message = input.gets
            message and message.chomp == MESSAGE_COMPLETE
          end
          break if @child_process_pipes.empty?
        end
      end

      def n_processes
        [[@n_clients, 1].max, max_n_processes].min
      end

      def max_n_processes
        Facter["processorcount"].value.to_i
      end

      def n_clients_per_process
        (@n_clients.to_f / n_processes).round
      end

      def n_requests_per_process
        (@requests.size.to_f / n_processes).round
      end
    end
  end
end
