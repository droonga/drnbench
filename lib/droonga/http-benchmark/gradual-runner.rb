# -*- coding: utf-8 -*-

require "droonga/http-benchmark/runner"

module Droonga
  module HttpBenchmark
    class GradualRunner
      attr_reader :start_n_clients, :end_n_clients, :step

      DEFAULT_START_N_CLIENTS = 1
      DEFAULT_END_N_CLIENTS = 1
      DEFAULT_STEP = 1

      def initialize(params)
        @start_n_clients = params[:start_n_clients] || DEFAULT_START_N_CLIENTS
        @end_n_clients = params[:end_n_clients] || DEFAULT_END_N_CLIENTS
        @step = params[:step] || DEFAULT_STEP
        @params = params
      end

      def run
        run_benchmarks
        puts @result.to_csv
      end

      private
      def run_benchmarks
        @result = Result.new
        @start_n_clients.step(@end_n_clients, @step) do |n_clients|
          benchmark = Runner.new(@params.merge(:n_clients => n_clients))
          puts "Running benchmark with #{n_clients} clients..."
          @result << benchmark.run
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
        "#{csv_header}\n#{csv_body}"
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
        (Runner::Result.keys + response_statuses).join(",")
      end

      def csv_body
        @results.values.collect do |result|
          (result.values +
           response_statuses.collect do |status|
             result.response_statuses[status] || 0
           end).join(",")
        end.join("\n")
      end
    end
    end
  end
end
