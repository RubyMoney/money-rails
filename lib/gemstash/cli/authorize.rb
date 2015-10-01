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
        raise Gemstash::CLI::Error.new(@cli, "To remove individual permissions, you do not need --remove
Instead just authorize with the new set of permissions") unless @args.empty?
        Gemstash::Authorization.remove(auth_key)
      end

      def save_authorization
        if @args.include?("all")
          raise Gemstash::CLI::Error.new(@cli, "Don't specify permissions to authorize for all")
        end

        @args.each do |arg|
          unless Gemstash::Authorization::VALID_PERMISSIONS.include?(arg)
            valid = Gemstash::Authorization::VALID_PERMISSIONS.join(", ")
            raise Gemstash::CLI::Error.new(@cli, "Invalid permission '#{arg}'\nValid permissions include: #{valid}")
          end
        end

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
