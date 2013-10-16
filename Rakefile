# -*- mode: ruby -*-

require "rubygems"
require "rubygems/package_task"
require "bundler/gem_helper"

base_dir = File.join(File.dirname(__FILE__))
helper = Bundler::GemHelper.new(base_dir)
def helper.version_tag
  version
end

helper.install
spec = helper.gemspec

Gem::PackageTask.new(spec) do |pkg|
end

task :test do
  ruby("test/run-test.rb")
end

task :default => :test
