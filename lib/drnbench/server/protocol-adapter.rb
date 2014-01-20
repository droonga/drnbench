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
