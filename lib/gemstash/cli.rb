require "gemstash"
require "thor"

class Gemstash::CLI < Thor
  autoload :Setup, "gemstash/cli/setup"

  def self.exit_on_failure?
    true
  end

  desc "setup", "Checks for dependencies and does initial setup"
  def setup
    Gemstash::CLI::Setup.new(self).run
  end

  desc "start", "Starts your gemstash server"
  def start
  end

  desc "stop", "Stops your gemstash server"
  def stop
  end
end
