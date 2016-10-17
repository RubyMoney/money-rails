require "gemstash"
require "active_support/core_ext/file/atomic"
require "dalli"
require "fileutils"
require "sequel"
require "uri"

module Gemstash
  # Storage for application-wide variables and configuration.
  class Env
    # The Gemstash::Env must be set before being retreived via
    # Gemstash::Env.current. This error is thrown when that is not honored.
    class EnvNotSetError < StandardError
    end

    # Little module to provide easy access to the current Gemstash::Env.
    module Helper
    private

      def gemstash_env
        Gemstash::Env.current
      end
    end

    # Rack middleware to set the Gemstash::Env for the app.
    class RackMiddleware
      def initialize(app, gemstash_env)
        @app = app
        @gemstash_env = gemstash_env
      end

      def call(env)
        env["gemstash.env"] = @gemstash_env
        @app.call(env)
      end
    end

    def initialize(config = nil, cache: nil, db: nil)
      @config = config
      @cache = cache
      @db = db
    end

    def self.available?
      !Thread.current[:gemstash_env].nil?
    end

    def self.current
      raise EnvNotSetError unless Thread.current[:gemstash_env]
      Thread.current[:gemstash_env]
    end

    def self.current=(value)
      Thread.current[:gemstash_env] = value
    end

    def self.daemonized?
      raise "Daemonized hasn't been set yet!" if @daemonized.nil?
      @daemonized
    end

    def self.daemonized=(value)
      value = false if value.nil?
      @daemonized = value
    end

    def config
      @config ||= Gemstash::Configuration.new
    end

    def config=(value)
      reset
      @config = value
    end

    def reset
      @config = nil
      @cache = nil
      @cache_client = nil
      @db = nil
    end

    def base_path
      dir = config[:base_path]

      if config.default?(:base_path)
        FileUtils.mkpath(dir) unless Dir.exist?(dir)
      else
        raise "Base path '#{dir}' is not writable" unless File.writable?(dir)
      end

      dir
    end

    def base_file(path)
      File.join(base_path, path)
    end

    def log_file
      base_file(config[:log_file] || "server.log")
    end

    def atomic_write(file, &block)
      File.atomic_write(file, File.dirname(file), &block)
    end

    def rackup
      File.expand_path("../config.ru", __FILE__)
    end

    def db
      @db ||= begin
        case config[:db_adapter]
        when "sqlite3"
          db_path = base_file("gemstash.db")

          db = if RUBY_PLATFORM == "java"
            Sequel.connect("jdbc:sqlite:#{db_path}", max_connections: 1)
          else
            Sequel.connect("sqlite://#{URI.escape(db_path)}", max_connections: 1)
          end
        when "postgres", "mysql", "mysql2"
          db = Sequel.connect(config[:db_url])
        else
          raise "Unsupported DB adapter: '#{config[:db_adapter]}'"
        end

        Gemstash::Env.migrate(db)
        db
      end
    end

    def self.migrate(db)
      Sequel.extension :migration
      migrations_dir = File.expand_path("../migrations", __FILE__)
      Sequel::Migrator.run(db, migrations_dir, :use_transactions => true)
    end

    def cache
      @cache ||= Gemstash::Cache.new(cache_client)
    end

    def cache_client
      @cache_client ||= begin
        case config[:cache_type]
        when "memory"
          Gemstash::LruReduxClient.new
        when "memcached"
          Dalli::Client.new(config[:memcached_servers])
        else
          raise "Invalid cache client: '#{config[:cache_type]}'"
        end
      end
    end
  end
end
