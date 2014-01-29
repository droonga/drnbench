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
