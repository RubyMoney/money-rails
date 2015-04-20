# encoding: utf-8

require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)

load 'rails/tasks/engine.rake' if File.exists?(APP_RAKEFILE)

require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task :default => "spec:all"
task :test => :spec
task :spec => :prepare_test_env

desc "Prepare money-rails engine test environment"
task :prepare_test_env do
  Rake.application['app:db:drop:all'].invoke
  Rake.application['app:db:migrate'].invoke
  Rake.application['app:db:test:prepare'].invoke
end

def run_with_gemfile(gemfile)
  sh "BUNDLE_GEMFILE='#{gemfile}' bundle install --quiet"
  sh "BUNDLE_GEMFILE='#{gemfile}' bundle exec rake -t spec"
end

namespace :spec do

  desc "Run Tests against mongoid (version 4)"
  task(:mongoid4) { run_with_gemfile 'gemfiles/mongoid4.gemfile' }

  desc "Run Tests against mongoid (version 3)"
  task(:mongoid3) { run_with_gemfile 'gemfiles/mongoid3.gemfile' }

  desc "Run Tests against mongoid (version 2)"
  task(:mongoid2) { run_with_gemfile 'gemfiles/mongoid2.gemfile' }

  desc "Run Tests against rails 4.2"
  task(:rails42) { run_with_gemfile 'gemfiles/rails42.gemfile' }

  desc "Run Tests against rails 4.1"
  task(:rails41) { run_with_gemfile 'gemfiles/rails41.gemfile' }

  desc "Run Tests against rails 4"
  task(:rails4) { run_with_gemfile 'gemfiles/rails4.gemfile' }

  desc "Run Tests against rails 3"
  task(:rails3) { run_with_gemfile 'gemfiles/rails3.gemfile' }

  desc "Run Tests against mongoid 2 & 3 & 4"
  task :mongoid => [:mongoid2, :mongoid3, :mongoid4]

  desc "Run Tests against rails 3 & 4 & 4.1 & 4.2"
  task :rails => [:rails3, :rails4, :rails41, :rails42]

  desc "Run Tests against all ORMs"
  task :all => [:rails, :mongoid]

end

desc "Update CONTRIBUTORS file"
task :contributors do
  sh "git shortlog -s | awk '{ print $2 \" \" $3 }' > CONTRIBUTORS"
end
