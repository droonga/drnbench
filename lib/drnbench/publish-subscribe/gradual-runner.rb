# -*- coding: utf-8 -*-

require "benchmark"
require "csv"

module Drnbench
  module PublishSubscribe
    class GradualRunner
      attr_reader :total_results

      def initialize(config)
        @config = config
        @runner = Runner.new(@config)
      end

      def run
        results = []
        @runner.setup
        begin
          @config.n_steps.times do
            run_once(results)
          end
        ensure
          @runner.teardown
        end
        @total_results = [
          ["case", "qps"],
        ]
        @total_results += results
      end

      private
      def run_once(results)
        @runner.increase_subscribers
        label = "#{@runner.n_subscribers} subscribers"
        GC.disable
        result = Benchmark.bm do |benchmark|
          benchmark.report(label) do
            @runner.run
          end
        end
        GC.enable
        GC.start
        result = result.join("").strip.gsub(/[()]/, "").split(/\s+/)
        qps = @config.n_publishings.to_f / result.last.to_f
        if @config.report_progressively
          puts "   (#{qps} queries per second)"
        end
        results << [label, qps]
      end
    end
  end
end
