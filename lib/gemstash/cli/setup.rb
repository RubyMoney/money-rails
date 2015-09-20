require "gemstash"
require "fileutils"
require "thor/error"
require "yaml"

module Gemstash
  class CLI
    #:nodoc:
    class Setup
      def initialize(cli)
        @cli = cli
        @config = {}
      end

      def run
        if setup? && !@cli.options[:redo]
          @cli.say @cli.set_color("Everything is already setup!", :green)
          return
        end

        ask_storage
        ask_cache
        check_cache
        store_config
        @cli.say @cli.set_color("You are all setup!", :green)
      end

    private

      def setup?
        File.exist?(Gemstash::Env.config_file)
      end

      def say_current_config(option, label)
        return if Gemstash::Env.default_config?(option)
        @cli.say "#{label}: #{Gemstash::Env.config[option]}"
      end

      def ask_storage
        say_current_config(:base_path, "Current base path")
        path = @cli.ask "Where should files go? [~/.gemstash]", :path => true
        path = "~/.gemstash" if path.empty?
        @config[:base_path] = File.expand_path(path)
      end

      def ask_cache
        say_current_config(:cache_type, "Current base path")
        options = %w(memory memcached)
        cache = nil

        until cache
          cache = @cli.ask "Cache with what? [MEMORY, memcached]"
          cache = cache.downcase
          cache = "memory" if cache.empty?
          cache = nil unless options.include?(cache)
        end

        @config[:cache_type] = cache
      end

      def check_cache
        @cli.say "Checking that cache is available"
        Gemstash::Env.config = @config
        Gemstash::Env.cache_client.alive!
      rescue
        raise Thor::Error, @cli.set_color("Cache is not available", :red)
      ensure
        Gemstash::Env.reset
      end

      def store_config
        config_file = Gemstash::Env.config_file
        FileUtils.mkpath(File.dirname(config_file))
        File.write(config_file, YAML.dump(@config))
      end
    end
  end
end
