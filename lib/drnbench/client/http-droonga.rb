# -*- coding: utf-8 -*-

module Drnbench
  class HttpDroongaClient < HttpClient
    DEFAULT_PATH_BASE = "/droonga"
    DEFAULT_COMMAND = "search"
    DEFAULT_METHOD = "POST"

    def initialize(params)
      @command = params[:command] || DEFAULT_COMMAND
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
          :path => "#{DEFAULT_PATH_BASE}/#{@command}",
        }
      end
    end
  end
end
