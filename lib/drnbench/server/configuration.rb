module Drnbench
  module Server
    class EngineConfiguration
      attr_accessor :host, :port, :tag,
      attr_accessor :base_path, :engine_config_path
      attr_accessor :fluentd, :fluentd_options

      def initialize
        @port            = 24224
        @host            = "localhost"
        @tag             = "droonga"
        @base_path       = Pathname(Dir.pwd)
        @fluentd         = "fluentd"
        @fluentd_options = []
      end

      def engine_config_path=(path)
        @engine_config_path = path
        engine_config_path
      end

      def engine_config_path
        Pathname(@engine_config_path).expand_path(@base_path)
      end
    end

    class ProtocolAdapterConfiguration
      attr_accessor :application_dir, :port, :receive_port, :default_dataset
      attr_accessor :node, :node_options
      attr_accessor :engine_config

      def initialize
        @application_dir = Pathname(Dir.pwd)
        @port            = 80
        @receive_port    = 14224
        @default_dataset = "Droonga"
        @node            = "node"
        @node_options    = []
        @engine_config   = nil
      end
    end
  end
end
