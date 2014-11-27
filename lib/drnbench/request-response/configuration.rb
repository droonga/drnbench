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

require "json"

module Drnbench
  module RequestResponse
    class Configuration
      attr_accessor :duration, :wait, :interval, :request_patterns_file
      attr_accessor :start_n_clients, :end_n_clients, :step, :n_requests
      attr_accessor :n_slow_requests, :n_fast_requests
      attr_accessor :mode
      attr_reader   :default_hosts
      attr_accessor :default_port, :default_path, :default_method, :default_timeout
      attr_accessor :report_progressively, :output_path

      MIN_DURATION = 1
      MIN_WAIT     = 0

      def initialize
        @duration             = 30
        @wait                 = 0.01
        @interval             = 10
        @start_n_clients      = 0
        @end_n_clients        = 1
        @step                 = 1
        @n_requests           = 1000
        @mode                 = :http
        @n_slow_requests      = 5
        @n_fast_requests      = 5

        @default_hosts        = ["localhost"]
        @default_port         = 80
        @default_path         = "/"
        @default_method       = "GET"
        @default_timeout      = 5.0

        @report_progressively = true
        @output_path          = "/tmp/drnbench-result.csv"

        @last_default_host_index = 0
      end

      def validate
        if @duration.nil?
          raise ArgumentError.new("You must specify the test duration.")
        end
        if @request_patterns_file.nil?
          raise ArgumentError.new("You must specify the path to the request patterns JSON file.")
        end
      end

      def duration
        [@duration, MIN_DURATION].max
      end

      def wait
        [@wait, MIN_WAIT].max
      end

      def mode
        @mode.to_sym
      end

      def request_patterns
        @request_patterns ||= prepare_request_patterns
      end

      def default_hosts=(hosts)
        @last_default_host_index = 0
        @default_hosts = hosts
      end

      def default_host
        host = @default_hosts[@last_default_host_index]
        @last_default_host_index += 1
        if @last_default_host_index == @default_hosts.size
          @last_default_host_index = 0
        end
        host
      end

      private
      def prepare_request_patterns
        request_patterns = File.read(@request_patterns_file)
        begin
          request_patterns = JSON.parse(request_patterns)
        rescue JSON::ParserError
          # it's a simple text file, list of paths
          request_patterns = request_patterns.strip.split(/\r?\n/)
        end
      end
    end
  end
end
