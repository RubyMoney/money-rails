# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gemstash/version"

Gem::Specification.new do |spec|
  spec.name          = "gemstash"
  spec.version       = Gemstash::VERSION
  spec.authors       = ["Andre Arko"]
  spec.email         = ["andre@arko.net"]

  spec.summary       = "A place to stash gems you'll need"
  spec.description   = "Gemstash acts as a local RubyGems server, caching \
copies of gems from RubyGems.org automatically, and eventually letting \
you push your own private gems as well."
  spec.homepage      = "https://github.com/bundler/gemstash"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject {|f|
    f.match(%r{^(test|spec|features)/})
  }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "dalli", "~> 2.7"
  spec.add_runtime_dependency "puma", "~> 2.14"
  spec.add_runtime_dependency "sinatra", "~> 1.4"
  spec.add_runtime_dependency "thor", "~> 0.19"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rack-test", "~> 0.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "rubocop", "~> 0.34"
end
