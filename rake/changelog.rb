# Helper class for updating CHANGELOG.md
class Changelog
  attr_reader :changelog

  def initialize
    @changelog = File.expand_path("../../CHANGELOG.md", __FILE__)
  end

  def run
    ensure_new_version_specified
    parse_current_version
    return unless missing_pull_requests?
    fetch_missing_pull_requests
    update_changelog
  end

  def ensure_new_version_specified
    require_relative "../lib/gemstash/version.rb"
    tags = `git tag -l`
    return unless tags.include? Gemstash::VERSION
    STDERR.puts "Please update lib/gemstash/version.rb with the new version first!"
    exit false
  end

  def parse_current_version
  end

  def missing_pull_requests?
  end

  def fetch_missing_pull_requests
  end

  def update_changelog
  end
end
