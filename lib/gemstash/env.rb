require "gemstash"
require "dalli"
require "fileutils"
require "sequel"
require "yaml"

module Gemstash
  #:nodoc:
  class Env
    DEFAULT_CONFIG = {
      :cache_type => "memory",
      :base_path => File.expand_path("~/.gemstash"),
      :db_adapter => "sqlite3",
      :min_threads => 0,
      :max_threads => 16,
      :port => 9292,
      :workers => 1,
      :rubygems_url => "https://www.rubygems.org",
      :strategy => :redirection,
    }.freeze

    def self.config
      @config ||= begin
        if File.exist?(config_file)
          config = YAML.load_file(config_file)
          config = DEFAULT_CONFIG.merge(config)
          config.freeze
        else
          DEFAULT_CONFIG
        end
      end
    end

    def self.config=(value)
      reset
      @config = DEFAULT_CONFIG.merge(value).freeze
    end

    def self.default_config?(option)
      config[option] == DEFAULT_CONFIG[option]
    end

    def self.reset
      @config = nil
      @cache = nil
      @cache_client = nil
      @db = nil
    end

    def self.min_threads
      config[:min_threads]
    end

    def self.max_threads
      config[:max_threads]
    end

    def self.port
      config[:port]
    end

    def self.workers
      config[:workers]
    end

    def self.pidfile
      File.join(base_dir, "puma.pid")
    end

    def self.base_dir
      config[:base_path]
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
          FileUtils.mkpath(base_dir) unless Dir.exist?(base_dir)
          db_path = File.join(base_dir, "gemstash.db")
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

    def self.rubygems_url
      config[:rubygems_url]
    end

    def self.strategy
      config[:strategy]
    end

    def self.gem_cache_path
      File.join(base_dir, "gem_cache")
    end
  end
end
