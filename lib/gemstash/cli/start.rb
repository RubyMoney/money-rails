require "gemstash"
require "puma/cli"

module Gemstash
  class CLI
    #:nodoc:
    class Start
      def initialize(cli)
        @cli = cli
      end

      def run
        store_config
        setup_logging
        logger = Gemstash::Logging.raw_logger
        Puma::CLI.new(args, Puma::Events.new(logger, logger)).run
      end

    private

      def setup_logging
        Gemstash::Logging.setup_logger(Gemstash::Env.log_file)
      end

      def store_config
        Gemstash::Env.config_file = @cli.options[:config_file]
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
          ["--daemon", "--pidfile", Gemstash::Env.base_file("puma.pid")]
        else
          []
        end
      end
    end
  end
end
