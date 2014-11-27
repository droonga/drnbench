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
  class HttpDroongaClient < HttpClient
    DEFAULT_PATH_BASE = "/droonga"
    DEFAULT_COMMAND   = "search"
    DEFAULT_METHOD    = "POST"

    def initialize(params)
      super
      @command = params[:command] || DEFAULT_COMMAND
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
