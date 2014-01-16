# Copyright (C) 2014  Droonga Project
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

require "json"
require "yajl"
require "pathname"

module Drnbench
  class ProtocolAdapter
    attr_reader :port

    def initialize(params)
      @engine = params[:engine]

      @host = params[:host] || "localhost"
      @port = params[:port] || 3003
      @receive_port = params[:receive_port] || 14224
      @default_dataset = params[:default_dataset] || "Droonga"

      @application_dir = Pathname(params[:application_dir])
      @node = params[:node]
      @node_options = params[:node_options]
    end

    def start
      setup
    end

    def stop
      teardown
    end

    def application_file
      @application_dir + "application.js"
    end

    private
    def setup
      command = [
        @node,
        application_file,
        *@node_options,
      ]
      env = {
        "DROONGA_ENGINE_DEFAULT_DATASEt" => @default_dataset,
        "DROONGA_ENGINE_HOST"            => @engine.host,
        "DROONGA_ENGINE_PORT"            => @engine.port,
        "DROONGA_ENGINE_TAG"             => @engine.tag,
        "DROONGA_ENGINE_RECEIVE_HOST"    => @host,
        "DROONGA_ENGINE_RECEIVE_PORT"    => @receive_port,
      }
      arguments = [env, *command]
      @pid = Process.spawn(*arguments)

      wait_until_ready
    end

    def teardown
      return unless temporary?

      Process.kill(:TERM, @pid)
      Process.wait(@pid)
    end

    def ready?
      begin
        socket = TCPSocket.new(@host, @port)
        socket.close
        true
      rescue Errno::ECONNREFUSED
        false
      end
    end

    def wait_until_ready
      until ready?
        sleep 1
      end
    end
  end
end
