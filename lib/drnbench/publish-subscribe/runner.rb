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
require "droonga/client"
require "drnbench/server/engine"
require "drnbench/server/protocol-adapter"

module Drnbench
  module PublishSubscribe
    class Runner
      def initialize(config)
        @config = config
        @published_messages = Queue.new
      end

      def n_subscribers
        @subscribers.size
      end

      def setup
        setup_server
        setup_subscribers
      end

      def teardown
        teardown_subscribers
        teardown_server
      end

      def run
        publishing_times = @config.n_publishings
        n_will_be_published_messages = @subscribers.size * publishing_times

        do_feed(publishing_times)
        receive_messages(n_will_be_published_messages)
      end

      def increase_subscribers
        if @subscribers.empty?
          new_n_subscribers = @config.start_n_subscribers
        else
          new_n_subscribers = @subscribers.size
        end
        add_subscribers(new_n_subscribers)
        ensure_subscribers_ready
      end

      private
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

      def setup_subscribers
        @subscribers = []
      end

      def teardown_subscribers
        @subscribers.each do |subscriber|
          subscriber.close
        end
      end

      def add_subscribers(n_subscribers)
        n_subscribers.times do
          message = @config.new_subscribe_request
          client = Droonga::Client.new(:protocol => :http,
                                       :host => @config.protocol_adapter.host,
                                       :port => @config.protocol_adapter.port)
          client.subscribe(message) do |published_message|
            @published_messages.push(published_message)
          end
          @subscribers << client
        end
      end

      def ensure_subscribers_ready
        sleep(1)
        2.times do
          do_feed(1)
          n_subscribers.times do
            @published_messages.pop
            break if @published_messages.empty?
          end
        end
        @published_messages.clear
      end

      def do_feed(count)
        Droonga::Client.open(:tag => @config.engine.tag,
                             :host => @config.engine.host,
                             :port => @config.engine.port) do |feeder|
          count.times do
            do_one_feed(feeder)
          end
        end
      end

      def do_one_feed(feeder)
        message = @config.new_feed
        feeder.send(message)
      end

      def receive_messages(count)
        n_published_messages = 0
        count.times do
          # we should implement "timeout" for too slow cases
          @published_messages.pop
          n_published_messages += 1
        end
        n_published_messages
      end
    end
  end
end
