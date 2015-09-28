require "gemstash"
require "dalli"
require "fileutils"
require "sequel"

module Gemstash
  # Storage for application-wide variables and configuration.
  class Env
    def self.config
      @config ||= Gemstash::Configuration.new
    end

    def self.config=(value)
      reset
      @config = value
    end

    def self.reset
      @config = nil
      @cache = nil
      @cache_client = nil
      @db = nil
    end

    def self.base_path
      dir = config[:base_path]

      if config.default?(:base_path)
        FileUtils.mkpath(dir) unless Dir.exist?(dir)
      else
        raise "Base path '#{dir}' is not writable" unless File.writable?(dir)
      end

      dir
    end

    def self.base_file(path)
      File.join(base_path, path)
    end

    def self.rackup
      File.expand_path("../config.ru", __FILE__)
    end

    def self.db
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

    def self.cache
      @cache ||= Gemstash::Cache.new(cache_client)
    end

    def self.cache_client
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
