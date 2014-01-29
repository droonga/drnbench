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
          response = client.request(request)
          @result << {
            :request => request,
            :status => response.code,
            :elapsed_time => Time.now - start_time,
          }
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
