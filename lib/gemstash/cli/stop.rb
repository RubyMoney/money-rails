require "gemstash"
require "puma/control_cli"

module Gemstash
  class CLI
    # This implements the command line stop task to stop the Gemstash server:
    #  $ gemstash stop
    class Stop < Gemstash::CLI::Base
      def run
        prepare
        Puma::ControlCLI.new(args).run
      end

    private

      def args
        pidfile_args + %w(stop)
      end
    end
  end
end
