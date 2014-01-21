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
        @config.n_steps.times do
          @runner.increase_subscribers
          label = "#{@runner.n_subscribers} subscribers"
          percentage = nil
          result = Benchmark.bm do |benchmark|
            benchmark.report(label) do
              published_messages = @runner.run
              percentage = published_messages.size.to_f / @config.n_publishings * 100
            end
          end
          if @config.report_progressively
            puts "=> #{percentage} % feeds are notified"
          end
          result = result.join("").strip.gsub(/[()]/, "").split(/\s+/)
          qps = @config.n_publishings.to_f / result.last.to_f
          if @config.report_progressively
            puts "   (#{qps} queries per second)"
          end
          results << [label, qps]
        end
        @runner.teardown
        @total_results = [
          ["case", "qps"],
        ]
        @total_results += results
      end
    end
  end
end
