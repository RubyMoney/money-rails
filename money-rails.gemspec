# -*- encoding: utf-8 -*-
require File.expand_path('../lib/money-rails/version', __FILE__)

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

  s.files         =  Dir.glob("{lib,spec,config}/**/*")
  s.files         += %w(CHANGELOG.md LICENSE README.md)
  s.files         += %w(Rakefile money-rails.gemspec)

  s.files.delete("spec/dummy/log")
  s.files.delete("spec/dummy/log/development.log")
  s.files.delete("spec/dummy/log/test.log")
  s.files.delete("spec/dummy/db/development.sqlite3")
  s.files.delete("spec/dummy/db/test.sqlite3")

  s.test_files    = s.files.grep(/^spec\//)

  s.require_path = "lib"

  s.add_dependency "money",         "~> 6.5.0"
  s.add_dependency "monetize",      "~> 1.1.0"
  s.add_dependency "activesupport", ">= 3.0"
  s.add_dependency "railties",      ">= 3.0"

  s.add_development_dependency "rails",       ">= 3.0"
  s.add_development_dependency "rspec-rails", "~> 3.0"
  s.add_development_dependency 'database_cleaner', ['>= 0.8.0', '< 1.4.0']
  s.add_development_dependency 'test-unit', '~> 3.0' if RUBY_VERSION =~ /^2\.2/
end
