# frozen_string_literal: true

require "rubygems"

# Default to rails7.0.gemfile if BUNDLE_GEMFILE is not set
default_gemfile = File.expand_path("../../../gemfiles/rails7.0.gemfile", __dir__)

if ENV["BUNDLE_GEMFILE"]
  puts "Using Gemfile: #{ENV['BUNDLE_GEMFILE']}"
else
  puts "No BUNDLE_GEMFILE specified, defaulting to rails7.0.gemfile"
  ENV["BUNDLE_GEMFILE"] = default_gemfile
end

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])

$LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)
