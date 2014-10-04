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
require "drnbench/request-response/request-pattern"

module Drnbench
  module RequestResponse
    class Runner
      attr_reader :n_clients, :result

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
    end
  end
end
