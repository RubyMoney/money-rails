require "gemstash"
require "puma/control_cli"

module Gemstash
  class CLI
    #:nodoc:
    class Stop
      def initialize(cli)
        @cli = cli
      end

      def run
        store_config
        Puma::ControlCLI.new(args).run
      end

    private

      def store_config
        config = Gemstash::Configuration.new(file: @cli.options[:config_file])
        Gemstash::Env.config = config
      end

      def args
        ["--pidfile", Gemstash::Env.base_file("puma.pid"), "stop"]
      end
    end
  end
end
