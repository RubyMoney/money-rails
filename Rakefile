require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require_relative "rake/changelog.rb"
require_relative "rake/doc.rb"

RuboCop::RakeTask.new

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(--color)
end

task spec: :rubocop
task default: :spec

desc "Update ChangeLog based on commits in master"
task :changelog do
  Changelog.new.run
end

desc "Generate markdown, man, text, and html documentation"
task :doc do
  Doc.new.run
end

task build: :doc
