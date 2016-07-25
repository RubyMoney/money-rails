require "yaml"
require "erb"

module Gemstash
  #:nodoc:
  class Configuration
    DEFAULTS = {
      cache_type: "memory",
      base_path: File.expand_path("~/.gemstash"),
      db_adapter: "sqlite3",
      bind: "tcp://0.0.0.0:9292",
      rubygems_url: "https://rubygems.org",
      protected_fetch: false,
      fetch_timeout: 20
    }.freeze

    DEFAULT_FILE = File.expand_path("~/.gemstash/config.yml").freeze

    # This error is thrown when a config file is explicitly specified that
    # doesn't exist.
    class MissingFileError < StandardError
      def initialize(file)
        super("Missing config file: #{file}")
      end
    end

    def initialize(file: nil, config: nil)
      if config
        @config = DEFAULTS.merge(config).freeze
        return
      end

      raise MissingFileError, file if file && !File.exist?(file)
      file ||= default_file

      if File.exist?(file)
        @config = parse_config(file)
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

  private

    def default_file
      File.exist?("#{DEFAULT_FILE}.erb") ? "#{DEFAULT_FILE}.erb" : DEFAULT_FILE
    end

    def parse_config(file)
      if file.end_with?(".erb")
        YAML.load(ERB.new(File.read(file)).result) || {}
      else
        YAML.load_file(file) || {}
      end
    end
  end
end
