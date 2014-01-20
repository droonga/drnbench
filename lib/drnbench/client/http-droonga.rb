# -*- coding: utf-8 -*-

module Drnbench
  class HttpDroongaClient < HttpClient
    DEFAULT_PATH_BASE = "/droonga"
    DEFAULT_COMMAND   = "search"
    DEFAULT_METHOD    = "POST"

    def initialize(params, config)
      super
      @command = params["command"] || DEFAULT_COMMAND
      @requests = populate_http_requests(@requests)
    end

    private
    def populate_http_requests(requests)
      requests.collect do |queries|
        {
          "body" => {
            "queries" => queries,
          },
        }
      end
    end

    def fixup_request(request)
      reqyest["path"]   ||= "#{DEFAULT_PATH_BASE}/#{@command}"
      request["method"] ||= DEFAULT_METHOD
      super
    end
  end
end
