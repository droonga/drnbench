require "drnbench/server/configuration"

module Drnbench
  module PublishSubscribe
    class Configuration
      attr_accessor :start_n_subscribers, :n_publishings, :n_steps, :timeout
      attr_accessor :subscribe_request_file, :feed_file, :engine, :protocol_adapter
      attr_accessor :report_progressively, :output_path

      def initialize
        @start_n_subscribers  = 1000
        @n_publishings        = 1000
        @n_steps              = 10
        @timeout              = 10

        @report_progressively = true
        @output_path          = "/tmp/drnbench-pubsub-result.csv"

        @engine           = Server::EngineConfiguration.new
        @protocol_adapter = Server::ProtocolAdapterConfiguration.new
        @protocol_adapter.engine = @engine
      end

      def validate
        if @subscribe_request_file.nil?
          raise ArgumentError.new("You must specify a JSON file for a message pattern to subscribe.")
        end
        if @feed_file_file.nil?
          raise ArgumentError.new("You must specify a JSON file for a message pattern to feed.")
        end
      end

      def subscribe_request
        @subscribe_request ||= prepare_subscribe_request
      end

      def new_subscribe_request
        Marshal.load(Marshal.dump(subscribe_request))
      end

      def feed
        @feed ||= prepare_feed
      end

      def new_feed
        Marshal.load(Marshal.dump(feed))
      end
 
      private
      def prepare_subscribe_request
        subscribe_request_file = Pathname(@subscribe_request_file).expand_path(Dir.pwd)
        JSON.parse(subscribe_request_file.read)
      end

      def prepare_feed
        feed_file = Pathname(@feed_file).expand_path(Dir.pwd)
        JSON.parse(feed_file.read)
      end
    end
  end
end
