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

require "drnbench/client/http"
require "drnbench/client/http-droonga"
require "drnbench/request-response/result"

module Drnbench
  module RequestResponse
    class Runner
      attr_reader :n_clients, :result

      def initialize(n_clients, config)
        n_clients = 1 if n_clients.zero?
        @n_clients = n_clients
        @config = config
        populate_requests
      end

      def run
        process_requests
        @result
      end

      private
      def process_requests
        requests_queue = Queue.new
        @requests.each do |request|
          requests_queue.push(request)
        end

        @result = Result.new(:n_clients => @n_clients,
                             :duration => @config.duration,
                             :n_slow_requests => @config.n_slow_requests)

        client_params = {
          :requests => requests_queue,
          :result   => @result,
        }
        @clients = @n_clients.times.collect do |index|
          client = nil
          case @config.mode
          when :http
            client = HttpClient.new(client_params, @config)
          when :http_droonga
            client = HttpDroongaClient.new(client_params, @config)
          else
            raise ArgumentError.new("Unknown mode: #{@config.mode}")
          end
          client.run
          client
        end

        start_time = Time.now
        while Time.now - start_time < @config.duration
          sleep 1
          if requests_queue.empty?
            puts "WORNING: requests queue becomes empty! (#{Time.now - start_time} sec)"
            @result.duration = Time.now - start_time
            break
          end
        end

        @clients.each do |client|
          client.stop
        end

        @result
      end

      def populate_requests
        @requests = []

        if @config.request_patterns.is_a?(Array)
          @config.request_patterns.each do |request_pattern|
            populate_request_pattern(request_pattern)
          end
        else
          @config.request_patterns.each do |key, request_pattern|
            populate_request_pattern(request_pattern)
          end
        end

        @requests.shuffle!
      end

      def populate_request_pattern(request_pattern)
        frequency = request_pattern["frequency"] || default_frequency
        n_requests = @config.n_requests * @config.end_n_clients * frequency.to_f

        base_patterns = nil
        if request_pattern["pattern"]
          base_patterns = [request_pattern["pattern"]]
        else
          base_patterns = request_pattern["patterns"]
        end
        base_patterns = base_patterns.shuffle

        n_requests.round.times do |count|
          pattern = base_patterns[count % base_patterns.size]
          if pattern.is_a?(String)
            pattern = { "path" => pattern }
          end
          pattern["host"] ||= request_pattern["host"]
          pattern["port"] ||= request_pattern["port"]
          pattern["method"] ||= request_pattern["method"]
          pattern["timeout"] ||= request_pattern["timeout"]
          @requests << pattern
        end
      end

      def default_frequency
        size = @config.request_patterns.size
        1.0 / size
      end
    end
  end
end
