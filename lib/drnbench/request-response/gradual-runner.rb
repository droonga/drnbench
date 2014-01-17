# -*- coding: utf-8 -*-

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
          Drnbench::Result.keys + statuses
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
