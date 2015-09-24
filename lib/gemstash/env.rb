require "gemstash"
require "dalli"
require "fileutils"
require "sequel"
require "yaml"

module Gemstash
  #:nodoc:
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
      FileUtils.mkpath(config[:base_path]) unless Dir.exist?(config[:base_path])
      config[:base_path]
    end

    def self.base_file(path)
      File.join(base_path, path)
    end

    def self.config_file=(file)
      @config_file = file
    end

    def self.config_file
      @config_file || File.expand_path("~/.gemstash/config.yml")
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

    def self.gem_cache_path
      File.join(config[:base_path], "gem_cache")
    end
  end
end
