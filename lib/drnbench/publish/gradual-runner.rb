# -*- coding: utf-8 -*-

require "benchmark"
require "csv"

module Drnbench
  module Publish
    class GradualRunner
      def initialize(params)
        @params = params
        @runner = Runner.new(:start_n_subscribers     => @params[:start_n_subscribers],
                             :n_publishings           => @params[:n_publishings],
                             :timeout                 => @params[:timeout],
                             :subscribe_request       => @params[:subscribe_request],
                             :feed                    => @params[:feed],
                             :engine_config           => @params[:engine_config],
                             :protocol_adapter_config => @params[:protocol_adapter_config])
      end

      def run
        results = []
        @params[:n_steps].times do |try_count|
          @runner.add_subscribers(@runner.n_subscribers) if try_count > 0
          label = "#{@runner.n_subscribers} subscribers"
          percentage = nil
          result = Benchmark.bm do |benchmark|
            benchmark.report(label) do
              published_messages = @runner.run
              percentage = published_messages.size.to_f / @params[:n_publishings] * 100
            end
          end
          puts "=> #{percentage} % feeds are notified"
          result = result.join("").strip.gsub(/[()]/, "").split(/\s+/)
          qps = @params[:n_publishings].to_f / result.last.to_f
          puts "   (#{qps} queries per second)"
          results << [label, qps]
        end
        total_results = [
          ["case", "qps"],
        ]
        total_results += results

        puts ""
        puts "Results (saved to #{@params[:output_path]}):"
        File.open(@params[:output_path], "w") do |file|
          total_results.each do |row|
            file.puts(CSV.generate_line(row))
            puts row.join(",")
          end
        end
      end
    end
  end
end
