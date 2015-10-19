require "yaml"

module Gemstash
  #:nodoc:
  class Configuration
    DEFAULTS = {
      :cache_type => "memory",
      :base_path => File.expand_path("~/.gemstash"),
      :db_adapter => "sqlite3",
      :bind => "tcp://0.0.0.0:9292",
      :rubygems_url => "https://www.rubygems.org"
    }.freeze

    DEFAULT_FILE = File.expand_path("~/.gemstash/config.yml").freeze

    def initialize(file: nil, config: nil)
      if config
        @config = DEFAULTS.merge(config).freeze
        return
      end

      file ||= DEFAULT_FILE

      if File.exist?(file)
        @config = YAML.load_file(file)
        @config = DEFAULTS.merge(@config)
        @config.freeze
      else
        @config = DEFAULTS
      end
    end

    def default?(key)
      @config[key] == DEFAULTS[key]
    end

    def [](key)
      @config[key]
    end
  end
end
