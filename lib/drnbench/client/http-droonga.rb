# -*- coding: utf-8 -*-

module Drnbench
  class HttpDroongaClient < HttpClient
    DEFAULT_PATH_BASE = "/droonga"
    DEFAULT_COMMAND   = "search"
    DEFAULT_METHOD    = "POST"

    def initialize(params, config)
      super
      @command = params["command"] || DEFAULT_COMMAND
    end

    private
    def fixup_request(request)
      request = {
        "body" => request,
      }
      request["path"]   ||= "#{DEFAULT_PATH_BASE}/#{@command}"
      request["method"] ||= DEFAULT_METHOD
      super(request)
    end
  end
end
