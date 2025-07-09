require 'rubygems'

# Default to rails7.0.gemfile if BUNDLE_GEMFILE is not set
default_gemfile = File.expand_path('../../../../gemfiles/rails7.0.gemfile', __FILE__)

unless ENV['BUNDLE_GEMFILE']
  puts "No BUNDLE_GEMFILE specified, defaulting to rails7.0.gemfile"
  ENV['BUNDLE_GEMFILE'] = default_gemfile
else
  puts "Using Gemfile: #{ENV['BUNDLE_GEMFILE']}"
end

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

$:.unshift File.expand_path('../../../../lib', __FILE__)
