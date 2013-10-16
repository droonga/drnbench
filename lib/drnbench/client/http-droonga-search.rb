# -*- coding: utf-8 -*-

module Drnbench
  class HttpDroongaSearchClient < HttpClient
    DEFAULT_PATH = "/droonga/search"
    DEFAULT_METHOD = "POST"

    def initialize(params)
      params[:path] ||= DEFAULT_PATH
      params[:method] ||= DEFAULT_METHOD
      params[:requests] = populate_http_requests(params[:requests])
      super
    end

    private
    def populate_http_requests(requests)
      requests.collect do |queries|
        {
          :body => {
            :queries => queries,
          },
        }
      end
    end
  end
end
