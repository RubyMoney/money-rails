require "gemstash"
require "active_support/core_ext/file/atomic"
require "fileutils"
require "yaml"

module Gemstash
  class CLI
    # This implements the command line setup task:
    #  $ gemstash setup
    class Setup < Gemstash::CLI::Base
      def initialize(cli)
        super
        @config = {}
      end

      def run
        if setup? && !@cli.options[:redo]
          @cli.say @cli.set_color("Everything is already setup!", :green)
          return
        end

        check_rubygems_version
        ask_storage
        ask_cache
        ask_database
        check_cache
        check_storage
        check_database
        store_config
        save_metadata
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
        return if gemstash_env.config.default?(option)
        @cli.say "#{label}: #{gemstash_env.config[option]}"
      end

      def ask_storage
        say_current_config(:base_path, "Current base path")
        path = @cli.ask "Where should files go? [~/.gemstash]", path: true
        path = Gemstash::Configuration::DEFAULTS[:base_path] if path.empty?
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
        ask_memcached_details if cache == "memcached"
      end

      def ask_memcached_details
        say_current_config(:memcached_servers, "Current Memcached servers")
        servers = @cli.ask "What is the comma separated Memcached servers? [localhost:11211]"
        servers = "localhost:11211" if servers.empty?
        @config[:memcached_servers] = servers
      end

      def ask_database
        say_current_config(:db_adapter, "Current database adapter")
        options = %w(sqlite3 postgres mysql)
        database = nil

        until database
          database = @cli.ask "What database adapter? [SQLITE3, postgres, mysql]"
          database = database.downcase
          database = "sqlite3" if database.empty?
          database = nil unless options.include?(database)
        end

        @config[:db_adapter] = database
        ask_database_details(database) unless database == "sqlite3"
      end

      def ask_database_details(database)
        say_current_config(:db_url, "Current database url")

        if RUBY_PLATFORM == "java"
          default_value = "jdbc:#{database}:///gemstash"
        else
          default_value = "#{database}:///gemstash"
        end

        url = @cli.ask "Where is the database? [#{default_value}]"
        url = default_value if url.empty?
        @config[:db_url] = url
      end

      def check_cache
        @cli.say "Checking that the cache is available"
        with_new_config { gemstash_env.cache_client.alive! }
      rescue => e
        say_error "Cache error", e
        raise Gemstash::CLI::Error.new(@cli, "The cache is not available")
      end

      def check_database
        @cli.say "Checking that the database is available"
        with_new_config { gemstash_env.db.test_connection }
      rescue => e
        say_error "Database error", e
        raise Gemstash::CLI::Error.new(@cli, "The database is not available")
      end

      def check_storage
        with_new_config do
          dir = gemstash_env.config[:base_path]

          if Dir.exist?(dir)
            # Do metadata check without using Gemstash::Storage.metadata because
            # we don't want to store metadata just yet
            metadata_file = gemstash_env.base_file("metadata.yml")
            break unless File.exist?(metadata_file)
            version = Gem::Version.new(YAML.load_file(metadata_file)[:gemstash_version])
            break if Gem::Requirement.new("<= #{Gemstash::VERSION}").satisfied_by?(Gem::Version.new(version))
            raise Gemstash::CLI::Error.new(@cli, "The base path already exists with a newer version of Gemstash")
          else
            @cli.say "Creating the file storage path '#{dir}'"
            FileUtils.mkpath(dir)
          end
        end
      end

      def store_config
        config_dir = File.dirname(config_file)
        FileUtils.mkpath(config_dir) unless Dir.exist?(config_dir)
        File.atomic_write(config_file) {|f| f.write(YAML.dump(@config)) }
      end

      def save_metadata
        with_new_config do
          # Touch metadata to ensure it gets written
          Gemstash::Storage.metadata
        end
      end

      def say_error(title, error)
        return unless @cli.options[:debug]
        @cli.say @cli.set_color("#{title}: #{error}", :red)

        error.backtrace.each do |line|
          @cli.say @cli.set_color("  #{line}", :red)
        end
      end

      def with_new_config
        gemstash_env.config = Gemstash::Configuration.new(config: @config)
        yield
      ensure
        gemstash_env.reset
      end
    end
  end
end
