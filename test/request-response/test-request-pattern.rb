# Copyright (C) 2014 Droonga Project
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require "ostruct"
require "drnbench/request-response/request-pattern"

module Drnbench::RequestResponse::RequestPattern
  class RequestResponsePatternsTest < Test::Unit::TestCase
    CONFIG = OpenStruct.new
    CONFIG.n_requests = 1
    CONFIG.end_n_clients = 1

    PATH_STRING = "/path/to/endpoint"
    PATTERN_HASH = { "path" => PATH_STRING }

    class PatternTest < self
      data("path string" => PATH_STRING,
           "hash" => PATTERN_HASH)
      def test_validation(source)
        Pattern.valid_source?(source)
      end
    end

    class PatternsGroupTest < self
      data("path string array" => [
             PATH_STRING,
           ],
           "hash array" => [
             PATTERN_HASH,
           ],
           "hash with path string array" => {
             "patterns" => [
               PATH_STRING,
             ],
           },
           "hash with hash array" => {
             "patterns" => [
               PATTERN_HASH,
             ],
           })
      def test_validation(source)
        PatternsGroup.valid_source?(source)
      end
    end

    class AbstractTest < self
      data("path string array" => [
             PATH_STRING,
           ],
           "pattern hash array" => [
             PATTERN_HASH,
           ],

           "group, hash with path string array" => {
             "patterns" => [
               PATH_STRING,
             ],
           },
           "group, hash with hash array" => {
             "patterns" => [
               PATTERN_HASH,
             ],
           },

           "array of groups, path string array" => [
             [PATH_STRING],
           ],
           "array of groups, hash array" => [
             [PATTERN_HASH],
           ],
           "array of groups, hash with path string array" => [
             { "patterns" => [PATH_STRING] },
           ],
           "array of groups, hash with hash array" => [
             { "patterns" => [PATTERN_HASH] },
           ],

           "named groups, path string array" => {
             "group" => [PATH_STRING],
           },
           "named groups, hash array" => {
             "group" => [PATTERN_HASH],
           },
           "named groups, hash with path string array" => {
             "group" => { "patterns" => [PATH_STRING] },
           },
           "named groups, hash with hash array" => {
             "group" => { "patterns" => [PATTERN_HASH] },
           })
      def test_parse(source)
        abstract = Abstract.new(source, CONFIG)
        assert_equal(PATH_STRING,
                     abstract.groups.first.patterns.first.path)
        assert_equal(1.0,
                     abstract.groups.first.frequency)
      end
    end
  end
end