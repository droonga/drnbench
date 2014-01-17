# -*- coding: utf-8 -*-

require "json"
require "yajl"
require "pathname"
require "droonga/client"
require "drnbench/server/engine"
require "drnbench/server/protocol-adapter"

module Drnbench
  module Publish
    class Runner
      attr_reader :n_subscribers

      def initialize(params)
        @params = params || {}

        @n_publishings = params[:n_publishings] || 0
        @timeout = params[:timeout] || 0

        subscribe_request_file = @params[:subscribe_request]
        subscribe_request_file = Pathname(subscribe_request_file).expand_path(Dir.pwd)
        @subscribe_request = JSON.parse(subscribe_request_file.read, :symbolize_names => true)

        feed_file = @params[:feed]
        feed_file = Pathname(feed_file).expand_path(Dir.pwd)
        @feed = JSON.parse(feed_file.read, :symbolize_names => true)

        @n_subscribers = 0

        @feeder = Droonga::Client.new(tag: "droonga", port: 23003)

        @server_config = @params[:server_config]
        setup_server
        setup_initial_subscribers
      end

      def setup_server
        @engine = Engine.new(@config.engine_config)
        @engine.start

        @protocol_adapter = ProtocolAdapter.new(@config.protocol_adapter_config)
        @protocol_adapter.start
      end

      def teardown_server
        @protocol_adapter.stop
        @engine.stop
      end

      def setup_initial_subscribers
        add_subscribers(@params[:start_n_subscribers])
      end

      def run
        @n_publishings.times do |index|
          do_feed
        end

        published_messages = []
        while published_messages.size != @n_publishings
          published_messages << @receiver.new_message
        end

        teardown_server
        published_messages
      end

      def add_subscribers(n_subscribers)
        n_subscribers.times do |index|
          @request[:path]
          @request[:method]
          @request[:body]
          @client.connection.send(message, :response => :one)
        end
        @n_subscribers += n_subscribers
      end

      def do_feed
        message = Marshal.load(Marshal.dump(@feed))
        message[:id]         = Time.now.to_f.to_s,
        message[:date]       = Time.now
        message[:statusCode] = 200
        @feeder.connection.send(message, :response => :none)
      end
    end
  end
end
