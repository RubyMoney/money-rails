require "set"

# Helper class for updating CHANGELOG.md
class Changelog
  attr_reader :changelog_file, :parsed, :parsed_current_version, :parsed_last_version, :missing_pull_requests

  def initialize
    @changelog_file = File.expand_path("../../CHANGELOG.md", __FILE__)
  end

  def run
    ensure_new_version_specified
    parse_changelog
    fetch_missing_pull_requests
    update_changelog
  end

  def ensure_new_version_specified
    tags = `git tag -l`
    return unless tags.include? Changelog.current_version
    Changelog.error("Please update lib/gemstash/version.rb with the new version first!")
  end

  def parse_changelog
    require "citrus"
    Citrus.load(File.expand_path("../changelog.citrus", __FILE__))
    @parsed = Changelog::Grammar.parse(File.read(changelog_file))
    @parsed_current_version = @parsed.versions.find {|version| version.number == Changelog.current_version }

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

      unless version =~ /\A\d+(\.\d+)*(\.pre\.\d+)?\z/
        error("Invalid last version: #{version}, instead use something like 1.1.0, or 1.1.0.pre.2")
      end

      version
    end
  end

  def fetch_missing_pull_requests
    require "octokit"
    Octokit.auto_paginate = true
    @missing_pull_requests = missing_pull_request_numbers.map {|pr| fetch_pull_request(pr) }
  end

  def fetch_pull_request(number)
    puts "Fetching pull request ##{number}"
    Octokit.pull_request("bundler/gemstash", number)
  end

  def missing_pull_request_numbers
    @missing_pull_request_numbers ||= begin
      commits = `git log --oneline HEAD ^v#{last_version} --grep "^Merge pull request"`.split("\n")
      pull_requests = commits.map {|commit| commit[/Merge pull request #(\d+)/, 1].to_i }
      documented = Set.new

      if parsed_current_version
        parsed_current_version.pull_requests.each do |pr|
          documented << pr.number.to_i
        end
      end

      pull_requests.sort.reject {|pr| documented.include?(pr) }
    end
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
    file.puts "## #{Changelog.current_version} (#{current_date})"
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
    puts "Fetching issue for ##{pull_request.number}"
    issue = pull_request.rels[:issue].get.data
    labels = issue.labels.map(&:name)

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
      puts "Fetching commits for ##{pr.number}"
      commits = pr.rels[:commits].get.data
      authors = commits.map(&:author).map {|author| "[@#{author.login}](#{author.html_url})" }.uniq
      file.puts "  - #{pr.title} ([##{pr.number}](#{pr.html_url}), #{authors.join(", ")})"
    end
  end

  def current_date
    @current_date ||= Time.now.strftime("%Y-%m-%d")
  end

  def self.error(msg)
    STDERR.puts(msg)
    exit(false)
  end

  def self.current_version
    @current_version ||= begin
      require_relative "../lib/gemstash/version.rb"

      unless Gemstash::VERSION =~ /\A\d+(\.\d+)*(\.pre\.\d+)?\z/
        error("Invalid version: #{Gemstash::VERSION}, instead use something like 1.1.0, or 1.1.0.pre.2")
      end

      Gemstash::VERSION
    end
  end
end
