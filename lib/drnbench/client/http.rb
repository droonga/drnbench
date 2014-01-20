# -*- coding: utf-8 -*-

require "thread"
require "droonga/client"
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
          request = fixup_request(request)

          client = Droonga::Client.new(:protocol => :http,
                                       :host => request["host"],
                                       :port => request["port"])
          request["headers"] ||= {}
          request["headers"]["user-agent"] = "Ruby/#{RUBY_VERSION} Droonga::Benchmark::Runner::HttpClient"
          start_time = Time.now
          client.request(request) do |response|
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
      request["host"] ||= @config.default_host
      request["port"] ||= @config.default_port
      request["path"] ||= @config.default_path
      request["method"] ||= @config.default_method
      request["method"] = request["method"].upcase
      request
    end
  end
end
