require "gemstash"
require "thor/error"

module Gemstash
  class CLI
    #:nodoc:
    class Setup
      def initialize(cli)
        @cli = cli
      end

      def run
        check_memcached
        success
      end

    private

      def check_memcached
        # TODO: Resolve this
        # @cli.say "Checking that memcached is available"
        # Gemstash::Env.memcached_client.alive!
      rescue
        raise Thor::Error, @cli.set_color("Memcached is not running", :red)
      end

      def success
        @cli.say @cli.set_color("Gemstash is ready to be started!", :green)
      end
    end
  end
end
