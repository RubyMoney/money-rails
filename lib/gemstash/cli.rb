require "gemstash"
require "thor"

module Gemstash
  #:nodoc:
  class CLI < Thor
    autoload :Setup, "gemstash/cli/setup"
    autoload :Start, "gemstash/cli/start"
    autoload :Stop,  "gemstash/cli/stop"

    def self.exit_on_failure?
      true
    end

    desc "setup", "Checks for dependencies and does initial setup"
    def setup
      Gemstash::CLI::Setup.new(self).run
    end

    desc "start", "Starts your gemstash server"
    method_option :daemonize, :type => :boolean, :default => true, :desc =>
      "Daemonize the server"
    def start
      Gemstash::CLI::Start.new(self).run
    end

    desc "stop", "Stops your gemstash server"
    def stop
      Gemstash::CLI::Stop.new(self).run
    end
  end
end
