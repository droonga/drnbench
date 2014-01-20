# -*- mode: ruby; coding: utf-8 -*-

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
  spec.license = "MIT"
  spec.files = [
    "README.md",
    "Rakefile",
    "Gemfile",
    "#{spec.name}.gemspec",
    "License.txt",
  ]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.test_files += Dir.glob("test/**/*")
  Dir.chdir("bin") do
    spec.executables = Dir.glob("*")
  end

  spec.add_runtime_dependency("json")
  spec.add_runtime_dependency("droonga-client")
  spec.add_runtime_dependency("drntest")

  spec.add_development_dependency("bundler")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("test-unit")
end
