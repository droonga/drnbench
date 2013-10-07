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
        Formatter.output_gradual_results(@results)
      end

      private
      def run_benchmarks
        @results = {}
        @start_n_clients.step(@end_n_clients, @step) do |n_clients|
          benchmark = Runner.new(@params.merge(:n_clients => n_clients))
          @results[n_clients] = benchmark.run
        end
      end
    end
  end
end
