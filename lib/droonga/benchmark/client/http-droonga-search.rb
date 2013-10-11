# -*- coding: utf-8 -*-

module Droonga
  module Benchmark
    class HttpDroongaSearchClient << HttpClient
      DEFAULT_PATH = "/droonga/search"
      DEFAULT_METHOD = "POST"

      def initialize(params)
        params[:path] ||= DEFAULT_PATH
        params[:method] ||= DEFAULT_METHOD
        super
        populate_requests
      end

      private
      def populate_requests
        @requests.collect! do |queries|
          {
            :body => {
              :queries => queries,
            },
          }
        end
      end
    end
  end
end
