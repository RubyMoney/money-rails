require "gemstash"
require "fileutils"
require "thor/error"
require "yaml"

module Gemstash
  class CLI
    # This implements the command line setup task:
    #  $ gemstash setup
    class Setup
      include Gemstash::Env::Helper

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
        ask_database
        ask_strategy
        check_cache
        check_storage
        check_database
        store_config
        @cli.say @cli.set_color("You are all setup!", :green)
      end

    private

      def config_file
        @cli.options[:config_file] || Gemstash::Configuration::DEFAULT_FILE
      end

      def setup?
        File.exist?(config_file)
      end

      def say_current_config(option, label)
        return if env.config.default?(option)
        @cli.say "#{label}: #{env.config[option]}"
      end

      def ask_storage
        say_current_config(:base_path, "Current base path")
        path = @cli.ask "Where should files go? [~/.gemstash]", :path => true
        path = "~/.gemstash" if path.empty?
        @config[:base_path] = File.expand_path(path)
      end

      def ask_cache
        say_current_config(:cache_type, "Current cache")
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

      def ask_database
        say_current_config(:db_adapter, "Current database adapter")
        options = %w(sqlite3 postgres)
        database = nil

        until database
          database = @cli.ask "What database adapter? [SQLITE3, postgres]"
          database = database.downcase
          database = "sqlite3" if database.empty?
          database = nil unless options.include?(database)
        end

        @config[:db_adapter] = database
        ask_postgres_details if database == "postgres"
      end

      def ask_postgres_details
        say_current_config(:db_url, "Current database url")
        url = @cli.ask "Where is the database? [postgres:///gemstash]"
        url = "postgres:///gemstash" if url.empty?
        @config[:db_url] = url
      end

      def ask_strategy
        say_current_config(:strategy, "Current strategy")
        options = %w(caching redirection)
        strategy = nil

        until strategy
          strategy = @cli.ask "What strategy? [CACHING, redirection]"
          strategy = strategy.downcase
          strategy = "caching" if strategy.empty?
          strategy = nil unless options.include?(strategy)
        end

        @config[:strategy] = strategy
      end

      def check_cache
        @cli.say "Checking that the cache is available"
        with_new_config { env.cache_client.alive! }
      rescue => e
        say_error "Cache error", e
        raise Thor::Error, @cli.set_color("The cache is not available", :red)
      end

      def check_database
        @cli.say "Checking that the database is available"
        with_new_config { env.db.test_connection }
      rescue => e
        say_error "Database error", e
        raise Thor::Error, @cli.set_color("The database is not available", :red)
      end

      def check_storage
        with_new_config do
          dir = env.config[:base_path]
          break if Dir.exist?(dir)
          @cli.say "Creating the file storage path '#{dir}'"
          FileUtils.mkpath(dir)
        end
      end

      def store_config
        config_dir = File.dirname(config_file)
        FileUtils.mkpath(config_dir) unless Dir.exist?(config_dir)
        File.write(config_file, YAML.dump(@config))
      end

      def say_error(title, error)
        return unless @cli.options[:debug]
        @cli.say @cli.set_color("#{title}: #{error}", :red)

        error.backtrace.each do |line|
          @cli.say @cli.set_color("  #{line}", :red)
        end
      end

      def with_new_config
        env.config = Gemstash::Configuration.new(config: @config)
        yield
      ensure
        env.reset
      end
    end
  end
end
