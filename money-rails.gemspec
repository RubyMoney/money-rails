# frozen_string_literal: true

require File.expand_path("lib/money-rails/version", __dir__)

Gem::Specification.new do |s|
  s.name          = "money-rails"
  s.version       = MoneyRails::VERSION
  s.platform      = Gem::Platform::RUBY
  s.license       = "MIT"
  s.authors       = ["Andreas Loupasakis", "Shane Emmons", "Simone Carletti"]
  s.email         = ["alup.rubymoney@gmail.com"]
  s.description   = "This library provides integration of RubyMoney - Money gem with Rails"
  s.summary       = "Money gem integration with Rails"
  s.homepage      = "https://github.com/RubyMoney/money-rails"

  s.files = `git ls-files -z -- lib/ config/ CHANGELOG.md LICENSE *.gemspec README.md`.split("\x0")

  s.require_path = "lib"

  s.required_ruby_version = ">= 3.1"

  s.add_dependency "money",         "~> 7.0"
  s.add_dependency "monetize",      "~> 2.0"
  s.add_dependency "activesupport", ">= 6.1"
  s.add_dependency "railties",      ">= 6.1"

  if s.respond_to?(:metadata)
    s.metadata["changelog_uri"] = "https://github.com/RubyMoney/money-rails/blob/master/CHANGELOG.md"
    s.metadata["source_code_uri"] = "https://github.com/RubyMoney/money-rails/"
    s.metadata["bug_tracker_uri"] = "https://github.com/RubyMoney/money-rails/issues"
    s.metadata["rubygems_mfa_required"] = "true"
  end
end
