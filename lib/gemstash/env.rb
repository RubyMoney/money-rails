require "gemstash"
require "dalli"
require "yaml"

module Gemstash
  #:nodoc:
  class Env
    DEFAULT_CONFIG = {
      :cache_type => "memory",
      :base_path => File.expand_path("~/.gemstash")
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
    end

    def self.min_threads
      0
    end

    def self.max_threads
      16
    end

    def self.port
      9292
    end

    def self.workers
      1
    end

    def self.pidfile
      File.join(base_dir, "puma.pid")
    end

    def self.base_dir
      File.expand_path("~/.gemstash")
    end

    def self.config_file
      File.expand_path("~/.gemstash/config.yml")
    end

    def self.rackup
      File.expand_path("../config.ru", __FILE__)
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
      "https://www.rubygems.org"
    end
  end
end
