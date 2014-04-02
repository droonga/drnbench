# Copyright (C) 2014  Droonga Project
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

require "tempfile"
require "fileutils"

require "drnbench/chart/gnuplot"

module Drnbench
  module Reporters
    class ThroughputReporter
      def initialize(label)
        @label = label
        @data_file = Tempfile.new("drnbench-throughput-data")
      end

      def add_data(time, qps)
        @data_file.puts([time, qps].join("\t"))
      end

      def report(output_directory)
        FileUtils.mkdir_p(output_directory)
        generate_chart(output_directory)
      end

      private
      def generate_chart(output_directory)
        @data_file.flush
        gnuplot = Chart::Gnuplot.new
        gnuplot.write(<<-INPUT)
set output "#{output_directory}/throughput.pdf"
set title "Throughput"

set xlabel "Time (second)"
set ylabel "Queries per Second (qps)"
plot "#{@data_file.path}" using 1:2 with linespoints linestyle 1 \\
   title "#{@label}"
        INPUT
        gnuplot.run
      end
    end
  end
end
