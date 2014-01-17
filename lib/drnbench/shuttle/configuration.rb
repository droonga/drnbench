module Drnbench
  module Shuttle
    class Configuration
      attr_accessor :duration, :wait, :request_patterns_file
      attr_accessor :start_n_clients, :end_n_clients, :step, :n_requests
      attr_accessor :mode
      attr_accessor :default_host, :default_port, :default_path, :default_method
      attr_accessor :report_progressively, :output_path

      MIN_DURATION = 1
      MIN_WAIT     = 0

      def initialize
        @wait                 = 1
        @start_n_clients      = 1
        @end_n_clients        = 1
        @step                 = 1
        @n_requests           = 1000
        @mode                 = :http

        @default_host         = "localhost"
        @default_port         = 80
        @default_path         = "/"
        @default_method       = "GET"

        @report_progressively = true
        @output_path          = "/tmp/drnbench-result.csv"
      end

      def validate
        if @duration.nil?
          raise ArgumentError.new("You must specify the test duration.")
        end
        if @request_patterns_file.nil?
          raise ArgumentError.new("You must specify the path to the request patterns JSON file.")
        end
      end

      def duration
        [@duration, MIN_DURATION].max
      end

      def wait
        [@wait, MIN_WAIT].max
      end

      def request_patterns
        @request_patterns ||= prepare_request_patterns
      end

      private
      def prepare_request_patterns
        request_patterns = File.read(@request_patterns_file)
        request_patterns = JSON.parse(request_patterns, :symbolize_names => true)
        

        if params[:request_pattern]
          params[:request_pattern][:frequency] = 1
          @request_patterns = [params[:request_pattern]]
        else
          @request_patterns = params[:request_patterns]
        end
      end
    end
  end
end
