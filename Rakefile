#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake'
require 'rspec/core/rake_task'

desc 'Run tests'
RSpec::Core::RakeTask.new(:test) do |t|
  t.rspec_opts = '--format documentation'
end

task :test
