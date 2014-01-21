# -*- coding: utf-8 -*-

require "json"
require "yajl"
require "pathname"
require "progressbar"
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
        @published_messages = Queue.new

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
        publishing_times = @config.n_publishings
        n_will_be_published_messages = @subscribers.size * publishing_times

        do_feed(publishing_times)
        published_messages = receive_messages(n_will_be_published_messages)

        teardown_server
        published_messages
      end

      def add_subscribers(n_subscribers)
        progressbar = ProgressBar.new("subscribe", n_subscribers, STDERR)
        n_subscribers.times do |index|
          message = @config.new_subscribe_request
          client = Droonga::Client.new(:protocol => :http,
                                       :host => @config.protocol_adapter.host,
                                       :port => @config.protocol_adapter.port)
          client.subscribe(message) do |published_message|
            @published_messages.push(published_message)
          end
          @subscribers << client
          progressbar.inc
        end
        progressbar.finish
      end

      def do_feed(count)
        progressbar = ProgressBar.new("feeds", count, STDERR)
        Droonga::Client.open(:tag => @config.engine.tag,
                             :host => @config.engine.host,
                             :port => @config.engine.port) do |feeder|
          count.times do |index|
            do_one_feed(feeder)
            progressbar.inc
          end
        end
        progressbar.finish
      end

      def do_one_feed(feeder)
        message = @config.new_feed
        message["id"]         = Time.now.to_f.to_s,
        message["date"]       = Time.now
        message["statusCode"] = 200
        feeder.send(message, :response => :none)
      end

      def receive_messages(count)
        progressbar = ProgressBar.new("received", count, STDERR)
        published_messages = []
        count.times do
          # we should implement "timeout" for too slow cases
          published_messages << @published_messages.pop
          progressbar.inc
        end
        progressbar.finish
        published_messages
      end
    end
  end
end
