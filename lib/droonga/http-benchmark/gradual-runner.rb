# -*- coding: utf-8 -*-

require "droonga/http-benchmark/runner"
require "csv"

module Droonga
  module HttpBenchmark
    class GradualRunner
      attr_reader :start_n_clients, :end_n_clients, :step,
                    :report_progressively, :result

      DEFAULT_START_N_CLIENTS = 1
      DEFAULT_END_N_CLIENTS = 1
      DEFAULT_STEP = 1

      def initialize(params)
        @start_n_clients = params[:start_n_clients] || DEFAULT_START_N_CLIENTS
        @end_n_clients = params[:end_n_clients] || DEFAULT_END_N_CLIENTS
        @step = params[:step] || DEFAULT_STEP
        @report_progressively = params[:report_progressively] || false
        @params = params
      end

      def run
        run_benchmarks
        @result
      end

      private
      def run_benchmarks
        @result = Result.new
        @start_n_clients.step(@end_n_clients, @step) do |n_clients|
          benchmark = Runner.new(@params.merge(:n_clients => n_clients))
          if @report_progressively
            puts "Running benchmark with #{n_clients} clients..."
          end
          benchmark.run
          if @report_progressively
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
          @response_statuses = nil
          @results[result.n_clients] = result
        end

        def response_statuses
          @response_statuses ||= prepare_response_statuses
        end

        def to_csv
          ([csv_header] + csv_body).collect do |row|
            CSV.generate_line(row)
          end.join("")
        end

        private
        def prepare_response_statuses
          response_statuses = []
          @results.each do |n_clients, result|
            response_statuses += result.response_statuses.keys
          end
          response_statuses.uniq!
          response_statuses.sort!
          response_statuses
        end

        def csv_header
          Runner::Result.keys + response_statuses
        end

        def csv_body
          @results.values.collect do |result|
            result.values +
            response_statuses.collect do |status|
              result.response_status_percentages[status] || 0
            end
          end
        end
      end
    end
  end
end
