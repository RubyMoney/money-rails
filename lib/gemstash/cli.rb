require "gemstash"
require "thor"
require "thor/error"

module Gemstash
  # Base Command Line Interface class.
  class CLI < Thor
    autoload :Authorize, "gemstash/cli/authorize"
    autoload :Setup,     "gemstash/cli/setup"
    autoload :Start,     "gemstash/cli/start"
    autoload :Stop,      "gemstash/cli/stop"

    # Thor::Error for the CLI, which colors the message red.
    class Error < Thor::Error
      def initialize(cli, message)
        super(cli.set_color(message, :red))
      end
    end

    def self.exit_on_failure?
      true
    end

    desc "authorize [PERMISSIONS...]", "Add authorizations to push/yank/unyank private gems"
    method_option :remove, :type => :boolean, :default => false, :desc =>
      "Remove an authorization key"
    method_option :config_file, :type => :string, :desc =>
      "Config file to save to"
    method_option :key, :type => :string, :desc =>
      "Authorization key to create/update/delete (optional unless deleting)"
    def authorize(*args)
      Gemstash::CLI::Authorize.new(self, *args).run
    end

    desc "setup", "Checks for dependencies and does initial setup"
    method_option :redo, :type => :boolean, :default => false, :desc =>
      "Redo configuration"
    method_option :debug, :type => :boolean, :default => false, :desc =>
      "Show detailed errors"
    method_option :config_file, :type => :string, :desc =>
      "Config file to save to"
    def setup
      Gemstash::CLI::Setup.new(self).run
    end

    desc "start", "Starts your gemstash server"
    method_option :daemonize, :type => :boolean, :default => true, :desc =>
      "Daemonize the server"
    method_option :config_file, :type => :string, :desc =>
      "Config file to load when starting"
    def start
      Gemstash::CLI::Start.new(self).run
    end

    desc "stop", "Stops your gemstash server"
    method_option :config_file, :type => :string, :desc =>
      "Config file to load when stopping"
    def stop
      Gemstash::CLI::Stop.new(self).run
    end
  end
end
