# encoding: utf-8

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task :default => "spec:all"
task :test => :spec

namespace :spec do
  desc "Run Tests against mongoid (version 3)"
  task :mongoid3 do
    sh "BUNDLE_GEMFILE='gemfiles/mongoid3.gemfile' bundle --quiet"
    sh "BUNDLE_GEMFILE='gemfiles/mongoid3.gemfile' bundle exec rake -t spec"
  end

  desc "Run Tests against mongoid (version 2)"
  task :mongoid2 do
    sh "BUNDLE_GEMFILE='gemfiles/mongoid2.gemfile' bundle --quiet"
    sh "BUNDLE_GEMFILE='gemfiles/mongoid2.gemfile' bundle exec rake -t spec"
  end

  desc "Run Tests against activerecord"
  task :activerecord do
    sh "bundle --quiet"
    sh "bundle exec rake -t spec"
  end

  desc "Run Tests against all ORMs"
  task :all do
    # Mongoid 3
    sh "BUNDLE_GEMFILE='gemfiles/mongoid3.gemfile' bundle --quiet"
    sh "BUNDLE_GEMFILE='gemfiles/mongoid3.gemfile' bundle exec rake -t spec"

    # Mongoid 2
    sh "BUNDLE_GEMFILE='gemfiles/mongoid2.gemfile' bundle --quiet"
    sh "BUNDLE_GEMFILE='gemfiles/mongoid2.gemfile' bundle exec rake -t spec"

    # ActiveRecord
    sh "bundle --quiet"
    sh "bundle exec rake -t spec"
  end
end

desc "Update CONTRIBUTORS file"
task :contributors do
  sh "git shortlog -s | awk '{ print $2 \" \" $3 }' > CONTRIBUTORS"
end
