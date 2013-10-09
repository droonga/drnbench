# -*- coding: utf-8 -*-

module Droonga
  module HttpBenchmark
    class Formatter
      class << self
        def output_gradual_results(results)
          http_statuses = []
          results.each do |n_clients, result|
            http_statuses += result[:responses].keys
          end
          http_statuses.uniq!
          http_statuses.sort!

          puts "n_clients,total_n_requests,queries_per_second," +
                 "#{http_statuses.join(",")}," +
                 "min_elapsed_time,max_elapsed_time,average_elapsed_time"
          results.each do |n_clients, result|
            result[:n_clients] = n_clients
            response_statuses = http_statuses.collect do |status|
              if result[:responses].include?(status)
                result[:responses][status]
              else
                0
              end
            end
            result[:response_statuses] = response_statuses.join(",")
            puts(("%{n_clients}," +
                    "%{total_n_requests}," +
                    "%{queries_per_second}," +
                    "%{response_statuses}," +
                    "%{min_elapsed_time}," +
                    "%{max_elapsed_time}," +
                    "%{average_elapsed_time}") % result)
          end
        end
      end
    end
  end
end
