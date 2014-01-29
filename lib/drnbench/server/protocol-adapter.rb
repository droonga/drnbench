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

require "pathname"

module Drnbench
  class ProtocolAdapter
    attr_reader :port

    def initialize(config)
      @config = config

      @host = @config.host
      @port = @config.port
      @receive_port = @config.receive_port
      @default_dataset = @config.default_dataset

      @application_dir = Pathname(@config.application_dir)
      @node = @config.node
      @node_options = @config.node_options
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
        application_file.to_s,
        *@node_options,
      ]
      env = {
        "DROONGA_ENGINE_DEFAULT_DATASET" => @default_dataset,
        "DROONGA_ENGINE_HOST"            => @config.engine.host,
        "DROONGA_ENGINE_PORT"            => @config.engine.port.to_s,
        "DROONGA_ENGINE_TAG"             => @config.engine.tag,
        "DROONGA_ENGINE_RECEIVE_HOST"    => @host,
        "DROONGA_ENGINE_RECEIVE_PORT"    => @receive_port.to_s,
      }
      arguments = [env, *command]
      @pid = Process.spawn(*arguments)

      wait_until_ready
    end

    def teardown
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
