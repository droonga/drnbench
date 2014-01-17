# -*- coding: utf-8 -*-

require "thread"
require "net/http"
require "json"

module Drnbench
  class HttpClient
    attr_reader :requests, :results, :wait

    def initialize(params, config)
      @requests = params[:requests]
      @result   = params[:result]
      @config   = config
    end

    def run
      @thread = Thread.new do
        loop do
          request = @requests.pop
          fixup_request(request)

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
          sleep @config.wait
        end
      end
      self
    end

    def stop
      @thread.exit
    end

    private
    def fixup_request(request)
      request[:host] ||= @config.default_host
      request[:port] ||= @config.default_port
      request[:path] ||= @config.default_path
      request[:method] ||= @config.default_method
      request[:method] = request[:method].upcase
      request
    end
  end
end
