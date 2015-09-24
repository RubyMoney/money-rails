module Gemstash
  #:nodoc:
  class Configuration
    DEFAULTS = {
      :cache_type => "memory",
      :base_path => File.expand_path("~/.gemstash"),
      :db_adapter => "sqlite3",
      :min_threads => 0,
      :max_threads => 16,
      :port => 9292,
      :workers => 1,
      :rubygems_url => "https://www.rubygems.org",
      :strategy => "redirection",
    }.freeze

    def initialize(file: nil, config: nil)
      if config
        @config = DEFAULTS.merge(config).freeze
        return
      end

      file ||= File.expand_path("~/.gemstash/config.yml")

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
