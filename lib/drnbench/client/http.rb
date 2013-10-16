# -*- coding: utf-8 -*-

require "thread"
require "net/http"
require "json"

module Drnbench
  class HttpClient
    attr_reader :requests, :results, :wait

    DEFAULT_PATH = "/"
    DEFAULT_METHOD = "GET"

    def initialize(params)
      @requests = params[:requests]
      @result = params[:result]
      @wait = params[:wait]

      @default_host = params[:host]
      @default_port = params[:port]
      @default_path = params[:path] || DEFAULT_PATH
      @default_method = params[:method] || DEFAULT_METHOD
    end

    def run
      @thread = Thread.new do
        loop do
          request = @requests.pop
          request[:host] ||= @default_host
          request[:port] ||= @default_port
          request[:path] ||= @default_path
          request[:method] ||= @default_method
          request[:method] = request[:method].upcase

          Net::HTTP.start(request[:host], request[:port]) do |http|
            header = {
              "user-agent" => "Ruby/#{RUBY_VERSION} Droonga::Benchmark::Runner::HttpClient"
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
            @result << {
              :request => request,
              :status => response.code,
              :elapsed_time => Time.now - start_time,
            }
          end
          sleep @wait
        end
      end
      self
    end

    def stop
      @thread.exit
    end
  end
end
