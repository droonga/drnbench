# -*- coding: utf-8 -*-

require "./runner"

module Droonga
  module HttpBenchmark
    class GradualRunner
      attr_reader :start_n_clients, :end_n_clients, :step

      def initialize(params)
        @start_n_clients = params[:start_n_clients]
        @end_n_clients = params[:end_n_clients]
        @step = params[:step]
      end

      def run
        run_benchmarks
        Formatter.output_gradual_results(@results)
      end

      private
      def run_benchmarks
        @results = {}
        @start_n_clients.step(@end_n_clients, @step) do |n_clients|
          benchmark = Runner.new(params.merge(:n_clients => n_clients))
          @results[n_clients] = benchmark.run
        end
      end
    end
  end
end
