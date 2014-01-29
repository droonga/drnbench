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

module Drnbench
  module Server
    class EngineConfiguration
      attr_accessor :host, :port, :tag
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
      attr_accessor :application_dir, :host, :port, :receive_port, :default_dataset
      attr_accessor :node, :node_options
      attr_accessor :engine

      def initialize
        @application_dir = Pathname(Dir.pwd)
        @host            = "localhost"
        @port            = 80
        @receive_port    = 14224
        @default_dataset = "Droonga"
        @node            = "node"
        @node_options    = []
        @engine          = nil
      end
    end
  end
end
