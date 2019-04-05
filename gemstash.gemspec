#  frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gemstash/version"

Gem::Specification.new do |spec|
  spec.name          = "gemstash"
  spec.version       = Gemstash::VERSION
  spec.authors       = ["Andre Arko"]
  spec.email         = ["andre@arko.net"]
  spec.platform      = "java" if RUBY_PLATFORM == "java"

  spec.summary       = "A place to stash gems you'll need"
  spec.description   = "Gemstash acts as a local RubyGems server, caching \
copies of gems from RubyGems.org automatically, and eventually letting \
you push your own private gems as well."
  spec.homepage      = "https://github.com/bundler/gemstash"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select {|f|
    f.match(/^(lib|exe|CHANGELOG|CODE_OF_CONDUCT|LICENSE)/)
  }
  # we don't check in man pages, but we need to ship them because
  # we use them to generate the long-form help for each command.
  spec.files += Dir.glob("lib/gemstash/man/**/*")

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", ">= 4.2", "< 6"
  spec.add_runtime_dependency "dalli", "~> 2.7"
  spec.add_runtime_dependency "faraday", "~> 0.9"
  spec.add_runtime_dependency "faraday_middleware", "~> 0.10"
  spec.add_runtime_dependency "lru_redux", "~> 1.1"
  spec.add_runtime_dependency "puma", "~> 3.10"
  spec.add_runtime_dependency "sequel", "~> 5.0"
  spec.add_runtime_dependency "server_health_check-rack", "~> 0.1"
  spec.add_runtime_dependency "sinatra", ">= 1.4", "< 3.0"
  spec.add_runtime_dependency "thor", "~> 0.20"

  # Run Gemstash with the mysql adapter
  # spec.add_runtime_dependency "mysql", "~> 2.9"
  # Run Gemstash with the mysql2 adapter
  # spec.add_runtime_dependency "mysql2", "~> 0.4"

  if RUBY_PLATFORM == "java"
    spec.add_runtime_dependency "jdbc-sqlite3", "~> 3.8"
  else
    spec.add_runtime_dependency "sqlite3", "~> 1.3"
  end

  spec.add_development_dependency "aruba", [">= 0.14"]
  spec.add_development_dependency "bundler", [">= 1.11", "< 3.0"]
  spec.add_development_dependency "citrus", "~> 3.0"
  spec.add_development_dependency "octokit", "~> 4.2"
  spec.add_development_dependency "pandoc_object_filters", "~> 0.2"
  spec.add_development_dependency "rack-test", "~> 1.1"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "rubocop", "= 0.67.1"
end
