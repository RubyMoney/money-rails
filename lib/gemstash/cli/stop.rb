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
        Puma::ControlCLI.new(args).run
      end

    private

      def args
        ["--pidfile", Gemstash::Env.pidfile, "stop"]
      end
    end
  end
end
