require "gemstash"
require "dalli"
require "fileutils"
require "sequel"

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

      def env
        Gemstash::Env.current
      end
    end

    def initialize(config = nil)
      @config = config
    end

    def self.current
      raise EnvNotSetError unless Thread.current[:gemstash_env]
      Thread.current[:gemstash_env]
    end

    def self.current=(value)
      Thread.current[:gemstash_env] = value
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

    def rackup
      File.expand_path("../config.ru", __FILE__)
    end

    def db
      @db ||= begin
        case config[:db_adapter]
        when "sqlite3"
          db_path = base_file("gemstash.db")
          db = Sequel.connect("sqlite://#{db_path}")
        when "postgres"
          db = Sequel.connect(config[:db_url])
        else
          raise "Unsupported DB adapter: '#{config[:db_adapter]}'"
        end

        Sequel.extension :migration
        migrations_dir = File.expand_path("../migrations", __FILE__)
        Sequel::Migrator.run(db, migrations_dir, :use_transactions => true)
        db
      end
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
          Dalli::Client.new
        else
          raise "Invalid cache client: '#{config[:cache_type]}'"
        end
      end
    end
  end
end
