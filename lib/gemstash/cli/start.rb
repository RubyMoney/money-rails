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
        store_config
        setup_logging
        Puma::CLI.new(args, Gemstash::Logging::PumaLogger.puma_events).run
      end

    private

      def setup_logging
        Gemstash::Logging.setup_logger(env.base_file("server.log"))
      end

      def store_config
        config = Gemstash::Configuration.new(file: @cli.options[:config_file])
        env.config = config
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
          ["--daemon", "--pidfile", env.base_file("puma.pid")]
        else
          []
        end
      end
    end
  end
end
