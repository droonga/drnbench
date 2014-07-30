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

module Drnbench
  module RequestResponse
    class Result
      attr_reader :n_clients, :statuses, :n_slow_requests
      attr_accessor :duration

      class << self
        def keys
          [
            :n_clients,
            :total_n_requests,
            :queries_per_second,
            :min_elapsed_time,
            :max_elapsed_time,
            :average_elapsed_time,
          ]
        end
      end

      def initialize(params)
        @n_clients = params[:n_clients]
        @duration = params[:duration]
        @n_slow_requests = params[:n_slow_requests] || 5

        @results = []
        @total_elapsed_time = 0.0
        @elapsed_times = []
        @statuses = {}
      end

      def <<(result)
        clear_cached_statistics

        @results << result

        @statuses[result[:status]] ||= 0
        @statuses[result[:status]] += 1

        @elapsed_times << result[:elapsed_time]
        @total_elapsed_time += result[:elapsed_time]
      end

      def total_n_requests
        @total_n_requests ||= @results.size
      end

      def queries_per_second
        @queries_per_second ||= total_n_requests.to_f / @duration
      end

      def status_percentages
        @status_percentages ||= prepare_status_percentages
      end

      def min_elapsed_time
        @min_elapsed_time ||= @elapsed_times.min
      end

      def max_elapsed_time
        @max_elapsed_time ||= @elapsed_times.max
      end

      def average_elapsed_time
        @average_elapsed_time ||= @total_elapsed_time / @elapsed_times.size
      end

      def top_slow_requests
        slow_requests[0..@n_slow_requests-1].collect do |result|
          request = result[:request]
          status = result[:status]
          if result[:status].zero?
            status = "#{status}(aborted)"
          end
          "#{result[:elapsed_time]} sec: " +
            "#{request["method"]} #{status} " +
            "http://#{request["host"]}:#{request["port"]}#{request["path"]}"
        end
      end

      def slow_requests
        @results.sort do |a, b|
          b[:elapsed_time] <=> a[:elapsed_time]
        end
      end

      def to_s
        "Total requests: #{total_n_requests} " +
          "(#{queries_per_second} queries per second)\n" +
        "Status:\n" +
        status_percentages.collect do |status, percentage|
          "  #{status}: #{percentage} %"
        end.join("\n") + "\n" +
        "Elapsed time:\n" +
        "  min:     #{min_elapsed_time} sec\n" +
        "  max:     #{max_elapsed_time} sec\n" +
        "  average: #{average_elapsed_time} sec\n" +
        "Top #{@n_slow_requests} slow requests:\n" +
        top_slow_requests.collect do |request|
          "  #{request}"
        end.join("\n")
      end

      def values
        self.class.keys.collect do |column|
          send(column)
        end
      end

      private
      def clear_cached_statistics
        @total_n_requests = nil
        @queries_per_second = nil
        @status_percentages = nil
        @min_elapsed_time = nil
        @max_elapsed_time = nil
        @average_elapsed_time = nil
      end

      def prepare_status_percentages
        status_percentages = []
        @statuses.each do |status, n_results|
          percentage = n_results.to_f / total_n_requests * 100
          status_percentages << {:percentage => percentage,
                                 :status => status}
        end
        status_percentages.sort! do |a, b|
          (-1) * (a[:percentage] <=> b[:percentage])
        end
        final_status_percentages = {}
        status_percentages.each do |status|
          final_status_percentages[status[:status]] = status[:percentage]
        end
        final_status_percentages
      end
    end
  end
end
