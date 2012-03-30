# -*- encoding: utf-8 -*-
require File.expand_path('../lib/money-rails/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = "money-rails"
  s.version       = MoneyRails::VERSION
  s.platform      = Gem::Platform::RUBY
  s.license       = "MIT"
  s.authors       = ["Andreas Loupasakis", "Shane Emmons", "Simone Carletti"]
  s.email         = ["alup.rubymoney@gmail.com"]
  s.description   = %q{This library provides integration of RubyMoney - Money gem with Rails}
  s.summary       = %q{Money gem integration with Rails}
  s.homepage      = "https://github.com/RubyMoney/money"

#  s.files         = `git ls-files`.split($\)
  s.files         =  Dir.glob("{lib,spec}/**/*")
  s.files         += %w(LICENSE README.md)
  s.files         += %w(money-rails.gemspec)


  s.test_files    = s.files.grep(%r{^(test|spec|features)/})

  s.require_path = "lib"

  s.add_dependency(%q<money>, [">= 4.0.2"])
  s.add_dependency(%q<activesupport>, [">= 3.0"])
  s.add_dependency(%q<railties>, [">= 3.0"])
end
