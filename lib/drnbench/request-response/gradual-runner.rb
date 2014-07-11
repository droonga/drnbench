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

require "drnbench/request-response/runner"
require "csv"

module Drnbench
  module RequestResponse
    class GradualRunner
      attr_reader :report_progressively, :result

      def initialize(config)
        @config = config
      end

      def run
        run_benchmarks
        @result
      end

      private
      def run_benchmarks
        @result = Result.new
        @config.start_n_clients.step(@config.end_n_clients, @config.step) do |n_clients|
          benchmark = Runner.new(n_clients, @config)
          if @config.report_progressively
            puts "Running benchmark with #{n_clients} clients..."
          end
          benchmark.run
          if @config.report_progressively
            puts benchmark.result.to_s
          end
          @result << benchmark.result
        end
      end

      class Result
        def initialize
          @results = {}
        end

        def <<(result)
          @statuses = nil
          @results[result.n_clients] = result
        end

        def statuses
          @statuses ||= prepare_statuses
        end

        def to_csv
          ([csv_header] + csv_body).collect do |row|
            CSV.generate_line(row)
          end.join("")
        end

        private
        def prepare_statuses
          statuses = []
          @results.each do |n_clients, result|
            statuses += result.statuses.keys
          end
          statuses.uniq!
          statuses.sort!
          statuses
        end

        def csv_header
          Drnbench::RequestResponse::Result.keys + statuses
        end

        def csv_body
          @results.values.collect do |result|
            result.values +
            statuses.collect do |status|
              result.status_percentages[status] || 0
            end
          end
        end
      end
    end
  end
end
