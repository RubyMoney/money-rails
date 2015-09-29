require "gemstash"
require "puma/control_cli"

module Gemstash
  class CLI
    # This implements the command line stop task to stop the Gemstash server:
    #  $ gemstash stop
    class Stop
      include Gemstash::Env::Helper

      def initialize(cli)
        Gemstash::Env.current = Gemstash::Env.new
        @cli = cli
      end

      def run
        store_config
        Puma::ControlCLI.new(args).run
      end

    private

      def store_config
        config = Gemstash::Configuration.new(file: @cli.options[:config_file])
        env.config = config
      end

      def args
        ["--pidfile", env.base_file("puma.pid"), "stop"]
      end
    end
  end
end
