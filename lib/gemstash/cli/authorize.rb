# frozen_string_literal: true

require "gemstash"
require "securerandom"

module Gemstash
  class CLI
    # This implements the command line authorize task to authorize users:
    #  $ gemstash authorize authorized-key
    class Authorize < Gemstash::CLI::Base
      def run
        prepare
        setup_logging

        if @cli.options[:remove]
          remove_authorization
        else
          save_authorization
        end
      end

    private

      def setup_logging
        Gemstash::Logging.setup_logger(gemstash_env.log_file)
      end

      def remove_authorization
        unless @args.empty?
          raise Gemstash::CLI::Error.new(@cli, "To remove individual permissions, you do not need --remove
Instead just authorize with the new set of permissions")
        end
        Gemstash::Authorization.remove(auth_key(false))
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

      def auth_key(allow_generate = true)
        if @cli.options[:key]
          @cli.options[:key]
        elsif allow_generate
          key = SecureRandom.hex(16)
          key = SecureRandom.hex(16) while Gemstash::Authorization[key]
          @cli.say "Your new key is: #{key}"
          key
        else
          raise Gemstash::CLI::Error.new(@cli, "The --key option is required to remove an authorization key")
        end
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
