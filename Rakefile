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

require 'rake'

task default: "spec:all"
task test: :spec
task spec: :prepare_test_env

desc "Prepare money-rails engine test environment"
task :prepare_test_env do
  load APP_RAKEFILE if File.exist?(APP_RAKEFILE)
  Rake.application["db:drop"].invoke
  Rake.application["db:create"].invoke
  Rake.application["db:test:prepare"].invoke
end

def run_with_gemfile(gemfile)
  Bundler.with_original_env do
    lockfile = "#{gemfile}.lock"
    File.delete(lockfile) if File.exist?(lockfile)
    sh "BUNDLE_GEMFILE=#{gemfile} bundle install --quiet"
    sh "BUNDLE_GEMFILE=#{gemfile} bundle exec rake spec"
  end
end

namespace :spec do
  frameworks_versions = {}

  Dir[GEMFILES_PATH].each do |gemfile|
    file_name = File.basename(gemfile, '.gemfile')
    _, framework, version = file_name.match(/\A([a-z_]+)([\d.]+)\z/).to_a
    major, _minor = version.split(".").map(&:to_i)

    # Rails 8+ requires Ruby 3.2+
    next if framework == 'active_record' && major >= 8 && RUBY_VERSION < '3.2'

    # activerecord-jdbc-adapter doesn't support Rails 8+ yet
    next if framework == 'active_record' && major >= 8 && RUBY_ENGINE == 'jruby'

    frameworks_versions[framework] ||= []
    frameworks_versions[framework] << file_name

    desc "Run tests against #{framework} #{version}"
    task(file_name) { run_with_gemfile gemfile }
  end

  frameworks_versions.each do |framework, versions|
    desc "Run tests against all supported #{framework} versions"
    task framework => versions
  end

  desc 'Run tests against all ORMs'
  task all: frameworks_versions.keys
end

desc "Update CONTRIBUTORS file"
task :contributors do
  list = `git shortlog -s`.lines.map do |line|
    line
      .split("\t")
      .last
      .sub(/Carlos Hernandez/, "Carlos Hernández")
      .sub(/Ralf S. Bongiolo/, "Ralf Schmitz Bongiolo")
      .gsub(/ó/, "ó")
  end
  File.write("CONTRIBUTORS", list.uniq.sort.join)
end

task "release:guard_clean" => :contributors
