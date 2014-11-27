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

require "thread"
require "droonga/client"
require "json"
require "drb"

module Drnbench
  class HttpClient
    attr_reader :runner, :results, :wait

    SUPPORTED_HTTP_METHODS = ["GET", "POST"]

    @@count = 0

    def initialize(params)
      @runner   = params[:runner]
      @config   = params[:config]
      @count    = 0
      @id       = @@count
      @@count += 1
      @thread = nil
    end

    def run
      @thread = Thread.new do
        start_time = Time.now
        loop do
          if @runner.empty?
            puts "WORNING: requests queue becomes empty! (#{Time.now - start_time} sec)"
            stop
            break
          end

          request = @runner.pop_request
          request = fixup_request(request)

          client = Droonga::Client.new(:protocol => :http,
                                       :host => request["host"],
                                       :port => request["port"],
                                       :timeout => request["timeout"])
          request["headers"] ||= {}
          request["headers"]["user-agent"] = "Ruby/#{RUBY_VERSION} Droonga::Benchmark::Runner::HttpClient"
          start_time = Time.now
          @last_request = request
          @last_start_time = start_time
          begin
          response = client.request(request)
            @runner.push_result(
              :request => request,
              :status => response.code,
              :elapsed_time => Time.now - start_time,
              :client => @id,
              :index => @count,
            )
          rescue Timeout::Error
            @runner.push_result(
              :request => request,
              :status => "0",
              :elapsed_time => Time.now - start_time,
              :client => @id,
              :index => @count,
            )
          end
          @last_request = nil
          @last_start_time = nil
          @count += 1
          sleep @config.wait
        end
      end
      self
    end

    def stop
      return unless @thread

      @thread.exit
      @thread = nil

      if @last_request
        @runner.push_result(
          :request => @last_request,
          :status => "0",
          :elapsed_time => Time.now - @last_start_time,
          :client => @id,
          :index => @count,
          :last => true,
        )
      end
    end

    def running?
      not @thread.nil?
    end

    private
    def fixup_request(request)
      request["host"] ||= @config.default_host
      request["port"] ||= @config.default_port
      request["path"] ||= @config.default_path
      request["method"] ||= @config.default_method
      request["method"] = request["method"].upcase
      unless SUPPORTED_HTTP_METHODS.include?(request["method"])
        request["method"] = "GET"
      end
      request["timeout"] ||= @config.default_timeout
      request
    end
  end
end
