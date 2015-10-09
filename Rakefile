require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(--color)
end

task :spec => :rubocop
task :default => :spec

desc "Generate Table of Contents for certain docs"
task :toc do
  toc_dir = File.expand_path("../tmp/", __FILE__)
  toc = File.join(toc_dir, "gh-md-toc")

  unless File.exist?(toc)
    require "open-uri"
    toc_contents = open("https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc", &:read)
    Dir.mkdir(toc_dir) unless Dir.exist?(toc_dir)
    File.write(toc, toc_contents)
    File.chmod(0776, toc)
  end

  doc = File.expand_path("../docs/reference.md", __FILE__)
  old_contents = File.read(doc)
  old_contents.sub!(/\A.*?^---$/m, "---")
  File.write(doc, old_contents)
  toc_contents = `"#{toc}" "#{doc}"`
  toc_contents.sub!(/Created by.*$/, "")
  File.write(doc, "#{toc_contents}\n#{old_contents}")
end
