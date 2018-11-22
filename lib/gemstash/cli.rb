# frozen_string_literal: true

require "gemstash"
require "thor"
require "thor/error"

module Gemstash
  # Base Command Line Interface class.
  class CLI < Thor
    autoload :Authorize, "gemstash/cli/authorize"
    autoload :Base,      "gemstash/cli/base"
    autoload :Setup,     "gemstash/cli/setup"
    autoload :Start,     "gemstash/cli/start"
    autoload :Status,    "gemstash/cli/status"
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

    def self.start(args = ARGV)
      help_flags = %w[-h --help]

      if args.any? {|a| help_flags.include?(a) }
        super(%w[help] + args.reject {|a| help_flags.include?(a) })
      else
        super
      end
    end

    def help(command = nil)
      command ||= "readme"
      page = manpage(command)

      if page && which("man")
        exec "man", page
      elsif page
        puts File.read("#{page}.txt")
      else
        super
      end
    end

    desc "authorize [PERMISSIONS...]", "Add authorizations to push/yank private gems"
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

    desc "status", "Check the status of your gemstash server"
    method_option :config_file, :type => :string, :desc =>
      "Config file to load when checking the status"
    def status
      Gemstash::CLI::Status.new(self).run
    end

    desc "stop", "Stops your gemstash server"
    method_option :config_file, :type => :string, :desc =>
      "Config file to load when stopping"
    def stop
      Gemstash::CLI::Stop.new(self).run
    end

    desc "version", "Prints gemstash version information"
    def version
      say "Gemstash version #{Gemstash::VERSION}"
    end
    map %w[-v --version] => :version

  private

    def manpage(command)
      page = File.expand_path("../man/gemstash-#{command}", __FILE__)
      return page if File.file?(page)

      1.upto(8) do |section|
        page = File.expand_path("../man/gemstash-#{command}.#{section}", __FILE__)
        return page if File.file?(page)
      end

      nil
    end

    def which(executable)
      ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
        exe_path = File.join(path, executable)
        return exe_path if File.file?(exe_path) && File.executable?(exe_path)
      end

      nil
    end
  end
end
