# frozen_string_literal: true
# coding: utf-8

version = ENV["SPEC_VERSION"]
version = "0.1.0" if version.to_s.empty?

Gem::Specification.new do |spec|
  spec.name          = "speaker"
  spec.version       = version
  spec.authors       = ["Mike Virata-Stone"]
  spec.email         = ["mike@virata-stone.com"]
  spec.platform      = "java" if RUBY_PLATFORM == "java"

  spec.summary       = "A gem that isn't real."
  spec.description   = "This is an example gem for testing purposes."
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = Dir.glob("exe/**/*") + Dir.glob("lib/**/*")
  spec.bindir        = "exe"
  spec.executables   = ["speaker"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
