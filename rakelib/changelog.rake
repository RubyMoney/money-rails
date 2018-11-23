# frozen_string_literal: true

require "forwardable"
require "open3"
require "set"

# Helper class for updating CHANGELOG.md
class Changelog
  attr_reader :changelog_file, :parsed, :parsed_current_version, :parsed_last_version, :missing_pull_requests

  def initialize
    @changelog_file = File.expand_path("../CHANGELOG.md", __dir__)
  end

  def run
    ensure_new_version_specified
    update_master_version
    parse_changelog
    fetch_missing_pull_requests
    update_changelog
  end

  def ensure_new_version_specified
    tags = `git tag -l`
    return unless tags.include? Changelog.current_version

    print "Are you updating the 'master' CHANGELOG? [yes/no] "
    abort("Please update lib/gemstash/version.rb with the new version first!") unless STDIN.gets.strip.casecmp("yes").zero?
    @master_update = true
  end

  def master_update?
    @master_update
  end

  def update_master_version
    return if master_update?

    contents = File.read(changelog_file)
    return unless contents =~ /^## master \(unreleased\)$/

    contents.sub!(/^## master \(unreleased\)$/, "## #{current_version} (#{current_date})")
    File.write(changelog_file, contents)
  end

  def current_version
    if master_update?
      "master"
    else
      Changelog.current_version
    end
  end

  def parse_changelog
    require "citrus"
    Citrus.load(File.expand_path("../rake/changelog.citrus", __dir__))
    @parsed = Changelog::Grammar.parse(File.read(changelog_file))
    @parsed_current_version = @parsed.versions.find {|version| version.number == current_version }

    if @parsed_current_version
      index = @parsed.versions.index(@parsed_current_version)
      @parsed_last_version = @parsed.versions[index + 1]
    else
      @parsed_last_version = @parsed.versions.first
    end
  end

  def last_version
    @last_version ||= begin
      version = parsed_last_version.number

      abort("Invalid last version: #{version}, instead use something like 1.1.0, or 1.1.0.pre.2") unless /\A\d+(\.\d+)*(\.pre\.\d+)?\z/.match?(version)

      version
    end
  end

  def octokit
    @octokit ||= begin
      require "octokit"
      token_path = File.expand_path("../.rake_github_token", __dir__)

      if File.exist?(token_path)
        options = { access_token: File.read(token_path).strip }
      else
        puts "\e[31mWARNING:\e[0m You do not have a GitHub OAuth token configured"
        puts "Please generate one at: https://github.com/settings/tokens"
        puts "And store it at: #{token_path}"
        puts "Otherwise you might hit rate limits while running this"
        print "Continue without token? [yes/no] "
        abort("Please create your token and retry") unless STDIN.gets.strip.casecmp("yes").zero?
        options = {}
      end

      client = Octokit::Client.new(options)
      client.auto_paginate = true
      client
    end
  end

  def fetch_missing_pull_requests
    @missing_pull_requests = MissingPullRequestFetcher.new(self).fetch
  end

  def update_changelog
    return if missing_pull_requests.empty?

    File.open(changelog_file, "w") do |file|
      begin
        write_current_version(file)
      ensure
        parsed.versions.each do |version|
          next if version == parsed_current_version

          file.write version.value
        end
      end
    end
  end

  def write_current_version(file)
    pull_requests_by_section = missing_pull_requests.group_by {|pr| section_for(pr) }

    file.puts "## #{current_version} (#{current_date})"
    file.puts

    if parsed_current_version
      file.puts parsed_current_version.description if parsed_current_version.description

      parsed_current_version.sections.each do |section|
        if pull_requests_by_section[section.title].to_a.empty?
          file.write section.value
        else
          file.write section.heading
          section.changes.each {|change| file.write change.value }
          write_pull_requests(file, pull_requests_by_section[section.title])
          file.puts
          pull_requests_by_section.delete(section.title)
        end
      end
    end

    pull_requests_by_section.keys.sort.each do |section_title|
      file.puts "### #{section_title}"
      file.puts
      write_pull_requests(file, pull_requests_by_section[section_title])
      file.puts
    end
  end

  def section_for(pull_request)
    labels = pull_request.issue.labels.map(&:name)

    if labels.include?("bug")
      "Bugfixes"
    elsif labels.include?("enhancement")
      "Features"
    else
      "Changes"
    end
  end

  def write_pull_requests(file, pull_requests)
    pull_requests.each do |pr|
      authors = pr.commits.map {|commit| author_link(commit) }.uniq
      file.puts "  - #{pr.title} ([##{pr.number}](#{pr.html_url}), #{authors.join(", ")})"
    end
  end

  def author_link(commit)
    @author_links ||= {}
    author = commit.author

    if author
      "[@#{author.login}](#{author.html_url})"
    elsif @author_links[commit.commit.author.name]
      @author_links[commit.commit.author.name]
    else
      puts "Cannot find GitHub link for author: #{commit.commit.author.name}"
      print "What is their GitHub username? "
      username = STDIN.gets.strip
      @author_links[commit.commit.author.name] = "[@#{username}](https://github.com/#{username})"
    end
  end

  def current_date
    @current_date ||=
      if master_update?
        "unreleased"
      else
        Time.now.strftime("%Y-%m-%d")
      end
  end

  def self.current_version
    @current_version ||= begin
      require_relative "../lib/gemstash/version.rb"

      abort("Invalid version: #{Gemstash::VERSION}, instead use something like 1.1.0, or 1.1.0.pre.2") unless Gemstash::VERSION.match?(/\A\d+(\.\d+)*(\.pre\.\d+)?\z/)

      Gemstash::VERSION
    end
  end

  # Wraps a pull request instance from octokit so we can expose obtaining the
  # commits and issue with a single method call.
  class PullRequest
    extend Forwardable
    def_delegators :@pull_request, :title, :number, :html_url

    def initialize(pull_request)
      @pull_request = pull_request
    end

    def commits
      @commits ||= begin
        puts "Fetching commits for ##{number}"
        @pull_request.rels[:commits].get.data
      end
    end

    def issue
      @issue ||= begin
        puts "Fetching issue for ##{number}"
        @pull_request.rels[:issue].get.data
      end
    end
  end

  # Helper class to fetch the pull requests that are missing from the CHANGELOG
  # for this branch.
  class MissingPullRequestFetcher
    extend Forwardable
    def_delegators :@changelog, :octokit, :parsed
    attr_reader :pull_requests

    def initialize(changelog)
      @changelog = changelog
    end

    def fetch
      fetch_all_pull_requests
      reject_documented_pull_requests
      reject_pull_requests_not_in_this_branch
      pull_requests
    end

  private

    def fetch_all_pull_requests
      puts "Fetching all pull requests"
      @pull_requests = octokit.pull_requests("bundler/gemstash", state: "all").
                       sort_by(&:number).map {|pr| PullRequest.new(pr) }
    end

    def reject_documented_pull_requests
      documented_prs = Set.new

      parsed.versions.each do |version|
        version.pull_requests.each do |pr|
          documented_prs << pr.number.to_i
        end
      end

      pull_requests.reject! {|pr| documented_prs.include?(pr.number) }
    end

    def reject_pull_requests_not_in_this_branch
      pull_requests.select! do |pr|
        pr.commits.all? do |commit|
          _, status = Open3.capture2e("git rev-list HEAD | grep '#{commit.sha}'")
          status.success?
        end
      end
    end
  end
end
