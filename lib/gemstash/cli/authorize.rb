require "gemstash"

module Gemstash
  class CLI
    # This implements the command line authorize task to authorize users:
    #  $ gemstash authorize authorized-key
    class Authorize
      include Gemstash::Env::Helper

      def initialize(cli, *args)
        Gemstash::Env.current = Gemstash::Env.new
        @cli = cli
        @args = args
      end

      def run
        store_config
        setup_logging

        if @cli.options[:remove]
          remove_authorization
        else
          save_authorization
        end
      end

    private

      def store_config
        config = Gemstash::Configuration.new(file: @cli.options[:config_file])
        env.config = config
      end

      def setup_logging
        Gemstash::Logging.setup_logger(env.base_file("server.log"))
      end

      def remove_authorization
        Gemstash::Authorization.remove(auth_key)
      end

      def save_authorization
        Gemstash::Authorization.authorize(auth_key, permissions)
      end

      def auth_key
        @cli.options[:key]
      end

      def permissions
        if @args.empty?
          "all"
        else
          @args
        end
      end
    end
  end
end
