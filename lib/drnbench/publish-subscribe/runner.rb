# -*- coding: utf-8 -*-

require "json"
require "yajl"
require "pathname"
require "droonga/client"
require "drnbench/server/engine"
require "drnbench/server/protocol-adapter"

module Drnbench
  module PublishSubscribe
    class Runner
      attr_reader :subscribers

      def initialize(config)
        @config = config

        @subscribers = []
        @published_messages = []

        @feeder = Droonga::Client.new(:tag => @config.engine.tag,
                                      :host => @config.engine.host,
                                      :port => @config.engine.port)

        setup_server
        setup_initial_subscribers
      end

      def setup_server
        @engine = Engine.new(@config.engine)
        @engine.start

        @protocol_adapter = ProtocolAdapter.new(@config.protocol_adapter)
        @protocol_adapter.start
      end

      def teardown_server
        @protocol_adapter.stop
        @engine.stop
      end

      def setup_initial_subscribers
        add_subscribers(@config.start_n_subscribers)
      end

      def run
        @config.n_publishings.times do |index|
          do_feed
        end

        published_messages = []
        while published_messages.size != @config.n_publishings
          published_messages << @receiver.new_message
        end

        teardown_server
        published_messages
      end

      def add_subscribers(n_subscribers)
        n_subscribers.times do |index|
          message = @config.new_subscribe_request
          client = Droonga::Client.new(:protocol => :http,
                                       :host => @config.protocol_adapter.host,
                                       :port => @config.protocol_adapter.port)
          client.subscribe(message) do |object|
            @published_messages << object
          end
          @subscribers << client
        end
      end

      def do_feed
        message = @config.new_feed
        message[:id]         = Time.now.to_f.to_s,
        message[:date]       = Time.now
        message[:statusCode] = 200
        @feeder.connection.send(message, :response => :none)
      end
    end
  end
end
