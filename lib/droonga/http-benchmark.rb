# -*- coding: utf-8 -*-

require "thread"
require "net/http"
require "json"

class HttpBenchmark
  attr_reader :duration, :n_clients

  MIN_DURATION = 1.0
  MIN_WAIT = 0
  MAX_N_CLIENTS = 16
  TOTAL_N_REQUESTS = 1000

  DEFAULT_HOST = "localhost"
  DEFAULT_PORT = 80
  DEFAULT_PATH = "/"
  DEFAULT_METHOD = "GET"

  def initialize(params)
    @duration = [params[:duration], MIN_DURATION].max
    @wait = [params[:wait], MIN_WAIT].max
    @n_clients = [params[:n_clients], MAX_N_CLIENTS].min
    @n_requests = params[:n_requests] || TOTAL_N_REQUESTS

    @default_host = params[:host] || DEFAULT_HOST
    @default_port = params[:port] || DEFAULT_PORT
    @default_path = params[:path] || DEFAULT_PATH
    @default_method = params[:method] || DEFAULT_METHOD

    if params[:request_pattern]
      params[:request_pattern][:frequency] = 1
      @request_patterns = [params[:request_pattern]]
    else
      @request_patterns = params[:request_patterns]
    end
    populate_requests
  end

  def run
    process_requests
    analyze_results
  end

  private
  def process_requests
    requests_queue = Queue.new
    results_queue = Queue.new

    @client_threads = 0.upto(@n_clients).collect do |index|
      Thread.new do
        loop do
          next if requests_queue.empty?
          request = requests_queue.pop
          Net::HTTP.new(request[:host], request[:port]) do |http|
            header = {
              "user-agent" => "Ruby/#{RUBY_VERSION} Droonga::HttpBenchmark"
            }
            response = nil
            start_time = Time.now
            case request[:method]
            when "GET"
              response = http.get(request[:path], header)
            when "POST"
              body = request[:body]
              unless body.is_a?(String)
                body = JSON.generate(body)
              end
              response = http.post(request[:path], body, header)
            end
            results_queue.push(:request => request,
                               :status => response.code,
                               :elapsed_time => Time.now - start_time)
          end
        end
      end
    end

    start_time = Time.now
    while Time.now - start_time < @duration
      if requests_queue.empty?
        @requests.each do |request|
          requests_queue.push(request)
        end
      end
    end

    @client_threads.each do |client_thread|
      client_thread.stop
    end

    @results = []
    while not results_queue.empty?
      @results << results_queue.pop
    end
  end

  def analyze_results
    total_n_requests = @results.size
    http_statuses = {}
    min_elapsed_time = @duration
    max_elapsed_time = 0
    total_elapsed_time = 0

    @results.each do |result|
      http_statuses[result[:status]] ||= 0
      http_statuses[result[:status]] += 1

      if result[:elapsed_time] < min_elapsed_time
        min_elapsed_time = result[:elapsed_time]
      end
      if result[:elapsed_time] > max_elapsed_time
        max_elapsed_time = result[:elapsed_time]
      end
      total_elapsed_time += result[:elapsed_time]
    end

    http_status_percentages = []
    http_statuses.each do |status, n_results|
      percentage = n_resulsts.to_f / total_n_requests * 100
      http_status_percentages << { :percentage => percentage,
                                   :status => status }
    end
    http_status_percentages.sort! do |a, b|
      (-1) * (a[:percentage] <=> b[:percentage])
    end

    puts "Total requests: #{total_n_requests} " +
           "(#{total_n_requests / @duration} queries per second)"
    puts "Status:"
    http_status_percentages.each do |status|
      puts "  #{status[:status]}: #{status[:percentage]} %"
    end
    puts "Elapsed time:"
    puts "  min:     #{min_elapsed_time} sec"
    puts "  max:     #{max_elapsed_time} sec"
    puts "  average: #{total_elapsed_time.to_f / total_elapsed_time} sec"
  end

  def populate_requests
    @requests = []
    @current_request = 0

    @request_patterns.each do |request_pattern|
      populate_request_pattern(request_pattern)
    end

    @requests.shuffle!
  end

  def populate_request_pattern(request_pattern)
    frequency = request_pattern[:frequency].to_f
    n_requests = @n_requests * frequency

    base_patterns = nil
    if request_pattern[:pattern]
      base_patterns = [request_pattern[:pattern]]
    else
      base_patterns = request_pattern[:patterns]
    end
    base_patterns = base_patterns.shuffle

    n_requests.times do |count|
      request = base_patterns[count % base_patterns.size]
      request[:host] ||= @default_host
      request[:port] ||= @default_port
      request[:path] ||= @default_path
      request[:method] ||= @default_method
      request[:method] = request[:method].upcase
      @requests << request
    end
  end
end
