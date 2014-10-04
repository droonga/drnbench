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

        abstract = Abstract.new(@config.request_patterns, @config)
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

      class Abstract
        def initialize(source, config)
          @source = source
          @config = config
        end

        def groups
          @groups ||= prepare_groups
        end

        def default_group_frequency
          1.0 / groups.size
        end

        def requests
          @requests ||= populate_requests
        end

        private
        def prepare_groups
          if @source.is_a?(Hash)
            return @source.values.collect do |group|
              PatternsGroup.new(group, self)
            end
          end

          if @source.is_a?(Array)
            if PatternsGroup.is_valid_source?(@source.first)
              return @source.collect do |group|
                PatternsGroup.new(group, self)
              end
            end
            if PatternsGroup.is_valid_source?(@source)
              return [
                PatternsGroup.new(@source, self),
              ]
            end
          end

          []
        end

        def populate_requests
          requests = []
          groups.each do |group|
            n_requests = @config.n_requests * @config.end_n_clients * group.frequency
            base_patterns = group.patterns.shuffle
            n_requests.round.times do |count|
              pattern = base_patterns[count % base_patterns.size]
              requests << pattern.to_request
            end
          end
        end
      end

      class PatternsGroup
        class << self
          def is_valid_source?(source)
            if source.is_a?(Array)
              return Pattern.is_valid_source?(source.first)
            end
            if source.is_a?(Hash)
              return source.has_key?("patterns")
            end
            raise "invalid group: #{JSON.stringify(source)}"
          end
        end

        attr_reader :abstract

        def initialize(source, abstract)
          @source = source
          @abstract = abstract
        end

        def frequency
          if @source.is_a?(Hash) and @source.has_key?("frequency")
            return @source["frequency"].to_f
          end
          @abstract.default_group_frequency
        end

        def host
          return nil unless @source.is_a?(Hash)
          @source["host"]
        end

        def port
          return nil unless @source.is_a?(Hash)
          @source["port"]
        end

        def method
          return nil unless @source.is_a?(Hash)
          @source["method"]
        end

        def timeout
          return nil unless @source.is_a?(Hash)
          @source["timeout"]
        end

        def patterns
          @patterns ||= prepare_patterns
        end

        private
        def prepare_patterns
          if @source.is_a?(Hash)
            if @source.has_key?("pattern")
              return [
                Pattern.new(@source["pattern"], self),
              ]
            else
              return @source["patterns"].collect do |pattern|
                Pattern.new(pattern, self)
              end
            end
          elsif @source.is_a?(Array)
            return @source.collect do |pattern|
              Pattern.new(pattern, self)
            end
          end
        end
      end

      class Pattern
        class << self
          def is_valid_source?(source)
            return true if source.is_a?(String)
            return false if source.is_a?(Array)
            return !source.has_key?("patterns") if source.is_a?(Hash)
            raise "invalid pattern: #{JSON.stringify(source)}"
          end
        end

        attr_reader :group

        def initialize(source, group)
          @source = source
          @group = group
        end

        def to_request
          @populated ||= populate
        end

        private
        def populate
          if @source.is_a?(String)
            request = { "path" => @source }
          else
            request = @source
          end
          request["host"] ||= @group.host
          request["port"] ||= @group.port
          request["method"] ||= @group.method
          request["timeout"] ||= @group.timeout
          request
        end
      end
    end
  end
end
