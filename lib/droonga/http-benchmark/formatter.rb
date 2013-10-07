# -*- coding: utf-8 -*-

module Droonga
  module HttpBenchmark
    class Formatter
      class << self
        def output_one_result(result)I
          puts "Total requests: #{result[:total_n_requests]} " +
                 "(#{result[:queries_per_second]} queries per second)"
          puts "Status:"
          result[:responses].each do |status, percentage|
            puts "  #{status}: #{percentage} %"
          end
          puts "Elapsed time:"
          puts "  min:     #{result[:min_elapsed_time} sec"
          puts "  max:     #{result[:max_elapsed_time} sec"
          puts "  average: #{result[:average_elapsed_time]} sec"
        end
      end
    end
  end
end
