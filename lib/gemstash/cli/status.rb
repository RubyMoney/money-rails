require "gemstash"
require "puma/control_cli"

module Gemstash
  class CLI
    # This implements the command line status task to check the server status:
    #  $ gemstash status
    class Status
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
        gemstash_env.config = config
      end

      def args
        ["--pidfile", gemstash_env.base_file("puma.pid"), "status"]
      end
    end
  end
end
