# -*- mode: ruby; coding: utf-8 -*-
#
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

clean_white_space = lambda do |entry|
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
require "drnbench/version"

Gem::Specification.new do |spec|
  spec.name = "drnbench"
  spec.version = Drnbench::VERSION
  spec.homepage = "https://github.com/groonga/grntest"
  spec.authors = ["YUKI Hiroshi", "Kouhei Sutou"]
  spec.email = ["yuki@clear-code.com", "kou@clear-code.com"]
  readme = File.read("README.md")
  readme.force_encoding("UTF-8") if readme.respond_to?(:force_encoding)
  entries = readme.split(/^\#\#\s(.*)$/)
  description = clean_white_space.call(entries[entries.index("Description") + 1])
  spec.summary, spec.description, = description.split(/\n\n+/, 3)
  spec.license = "GPLv3 or later"
  spec.files = [
    "README.md",
    "Rakefile",
    "Gemfile",
    "#{spec.name}.gemspec",
    "LICENSE.txt",
  ]
  spec.files += Dir.glob("doc/text/**/*")
  spec.files += Dir.glob("lib/**/*.rb")
  spec.test_files += Dir.glob("test/**/*")
  Dir.chdir("bin") do
    spec.executables = Dir.glob("*")
  end

  spec.add_runtime_dependency("json")
  spec.add_runtime_dependency("droonga-client")
  spec.add_runtime_dependency("drntest")
  spec.add_runtime_dependency("facter")
  spec.add_runtime_dependency("sigdump")

  spec.add_development_dependency("bundler")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("packnga")
  spec.add_development_dependency("kramdown")
  spec.add_development_dependency("test-unit")
end
