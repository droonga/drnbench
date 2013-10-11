# -*- coding: utf-8 -*-

module Droonga
  module Benchmark
    class Result
      attr_reader :n_clients, :duration, :statuses

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
        @max_elapsed_time ||= @elapsed_times.min
      end

      def average_elapsed_time
        @average_elapsed_time ||= @total_elapsed_time / @elapsed_times.size
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
        "  average: #{average_elapsed_time} sec"
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
        status_percentages = {}
        status_percentages.each do |status|
          status_percentages[status[:status]] = status[:percentage]
        end
        status_percentages
      end
    end
  end
end
