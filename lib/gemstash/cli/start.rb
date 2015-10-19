require "gemstash"
require "puma/cli"

module Gemstash
  class CLI
    # This implements the command line start task to start the Gemstash server:
    #  $ gemstash start
    class Start
      include Gemstash::Env::Helper

      def initialize(cli)
        Gemstash::Env.current = Gemstash::Env.new
        @cli = cli
      end

      def run
        check_rubygems_version
        store_config
        setup_logging
        store_daemonized
        Puma::CLI.new(args, Gemstash::Logging::StreamLogger.puma_events).run
      end

    private

      def setup_logging
        return unless daemonize?
        Gemstash::Logging.setup_logger(gemstash_env.base_file("server.log"))
      end

      def store_config
        config = Gemstash::Configuration.new(file: @cli.options[:config_file])
        gemstash_env.config = config
      end

      def store_daemonized
        Gemstash::Env.daemonized = daemonize?
      end

      def check_rubygems_version
        raise "Rubygems version is too old, please update rubygems by running: " \
              "gem update --system" unless
               Gem::Requirement.new("~> 2.4").satisfied_by?(Gem::Version.new(Gem::VERSION))
      end

      def daemonize?
        @cli.options[:daemonize]
      end

      def puma_config
        File.expand_path("../../puma.rb", __FILE__)
      end

      def args
        ["--config", puma_config] + daemonize_args
      end

      def daemonize_args
        if daemonize?
          ["--daemon", "--pidfile", gemstash_env.base_file("puma.pid")]
        else
          []
        end
      end
    end
  end
end
