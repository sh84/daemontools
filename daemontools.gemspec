# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'daemontools/version'

Gem::Specification.new do |gem|
  gem.authors       = ["sh"]
  gem.email         = ["cntyrf@gmail.com"]
  gem.description   = %q{Distributed storage}
  gem.summary       = %q{Distributed storage}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "daemontools"
  gem.require_paths = ["lib"]
  gem.version       = Daemontools::VERSION

  gem.add_development_dependency "bundler"
  gem.add_development_dependency "rake"
end
