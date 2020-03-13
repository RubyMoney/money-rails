require 'rubygems'

# The default gemfile is rails4
gemfile = File.expand_path('../../../../gemfiles/rails4.gemfile', __FILE__)

unless ENV['BUNDLE_GEMFILE']
	puts "No Gemfile specified, booting rails env with rails4.gemfile (default)"
	ENV['BUNDLE_GEMFILE'] ||= gemfile
end

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

gemfile = File.expand_path('../../../../Gemfile', __FILE__)

if File.exist?(gemfile)
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
end

$:.unshift File.expand_path('../../../../lib', __FILE__)