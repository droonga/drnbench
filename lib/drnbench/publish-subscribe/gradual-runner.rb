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
        @config.n_steps.times do |try_count|
          @runner.add_subscribers(@runner.subscribers.size) if try_count > 0
          label = "#{@runner.subscribers.size} subscribers"
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
        @total_results = [
          ["case", "qps"],
        ]
        @total_results += results
      end
    end
  end
end
