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
GEMFILES_PATH = 'gemfiles/*.gemfile'.freeze

load 'rails/tasks/engine.rake' if File.exist?(APP_RAKEFILE)

require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task default: "spec:all"
task test: :spec
task spec: :prepare_test_env

desc "Prepare money-rails engine test environment"
task :prepare_test_env do
  Rake.application['app:db:drop:all'].invoke
  Rake.application['app:db:create'].invoke if Rails::VERSION::MAJOR >= 5
  Rake.application['app:db:migrate'].invoke
  Rake.application['app:db:test:prepare'].invoke
end

def run_with_gemfile(gemfile)
  Bundler.with_clean_env do
    begin
      sh "BUNDLE_GEMFILE='#{gemfile}' bundle install --quiet"
      Rake.application['app:db:create'].invoke
      Rake.application['app:db:test:prepare'].invoke
      sh "BUNDLE_GEMFILE='#{gemfile}' bundle exec rake spec"
    ensure
      Rake.application['app:db:drop:all'].execute
    end
  end
end

namespace :spec do
  frameworks_versions = {}

  Dir[GEMFILES_PATH].each do |gemfile|
    file_name = File.basename(gemfile, '.gemfile')
    framework, version = file_name.split(/(\d+)/)
    major, minor = version.split(//)

    # Ruby 3 exclusions
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0')
      # Rails 5 does not support ruby-3.0.0 https://github.com/rails/rails/issues/40938#issuecomment-751569171
      # Mongoid gem does not yet support ruby-3.0.0 https://github.com/mongodb/mongoid#compatibility
      next if framework == 'mongoid' || (framework == 'rails' && version == "5")
    end

    frameworks_versions[framework] ||= []
    frameworks_versions[framework] << file_name

    desc "Run Tests against #{framework} #{[major, minor].compact.join('.')}"
    task(file_name) { run_with_gemfile gemfile }
  end

  frameworks_versions.each do |framework, versions|
    desc "Run Tests against all supported #{framework} versions"
    task framework => versions
  end

  desc 'Run Tests against all ORMs'
  task all: frameworks_versions.keys
end

desc "Update CONTRIBUTORS file"
task :contributors do
  sh "git shortlog -s | awk '{ print $2 \" \" $3 }' > CONTRIBUTORS"
end
