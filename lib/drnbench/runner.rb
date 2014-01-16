# -*- coding: utf-8 -*-

require "drnbench/client/http"
require "drnbench/client/http-droonga"
require "drnbench/result"

module Drnbench
  class Runner
    attr_reader :duration, :n_clients, :result

    MIN_DURATION = 1
    DEFAULT_DURATION = 10
    MIN_WAIT = 0
    DEFAULT_WAIT = 1
    DEFAULT_N_CLIENTS = 1
    TOTAL_N_REQUESTS = 1000

    def initialize(params)
      @duration = [params[:duration] || DEFAULT_DURATION, MIN_DURATION].max
      @n_clients = params[:n_clients] || DEFAULT_N_CLIENTS
      @n_requests = params[:n_requests] || TOTAL_N_REQUESTS

      params[:wait] ||= DEFAULT_WAIT
      params[:wait] = [params[:wait], MIN_WAIT].max

      @params = params

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
      @result
    end

    private
    def process_requests
      requests_queue = Queue.new
      @result = Result.new(:n_clients => @n_clients,
                           :duration => @duration)

      client_params = @params.merge(:requests => requests_queue,
                                    :result => @result)
      @clients = @n_clients.times.collect do |index|
        client = nil
        case @params[:mode]
        when :http
          client = HttpClient.new(client_params)
        when :http_droonga
          client = HttpDroongaClient.new(client_params)
        end
        client.run
        client
      end

      start_time = Time.now
      while Time.now - start_time < @duration
        if requests_queue.empty?
          @requests.each do |request|
            requests_queue.push(request)
          end
        end
        sleep 1
      end

      @clients.each do |client|
        client.stop
      end

      @result
    end

    def populate_requests
      @requests = []

      if @request_patterns.is_a?(Array)
        @request_patterns.each do |request_pattern|
          populate_request_pattern(request_pattern)
        end
      else
        @request_patterns.each do |key, request_pattern|
          populate_request_pattern(request_pattern)
        end
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

      n_requests.round.times do |count|
        @requests << base_patterns[count % base_patterns.size]
      end
    end
  end
end
