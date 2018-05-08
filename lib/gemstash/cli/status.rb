require "gemstash"
require "puma/control_cli"

module Gemstash
  class CLI
    # This implements the command line status task to check the server status:
    #  $ gemstash status
    class Status < Gemstash::CLI::Base
      def run
        prepare
        Puma::ControlCLI.new(args).run
      end

    private

      def args
        pidfile_args + %w[status]
      end
    end
  end
end
