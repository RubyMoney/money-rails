require "gemstash"

module Gemstash
  class CLI
    # Base class for common functionality for CLI tasks.
    class Base
      include Gemstash::Env::Helper

      def initialize(cli, *args)
        Gemstash::Env.current = Gemstash::Env.new
        @cli = cli
        @args = args
      end

    private

      def prepare
        check_rubygems_version
        store_config
        check_gemstash_version
      end

      def check_rubygems_version
        @cli.say(@cli.set_color("Rubygems version is too old, " \
                                 "please update rubygems by running: " \
                                 "gem update --system", :red)) unless
        Gem::Requirement.new(">= 2.4").satisfied_by?(Gem::Version.new(Gem::VERSION))
      end

      def store_config
        config = Gemstash::Configuration.new(file: @cli.options[:config_file])
        gemstash_env.config = config
      end

      def check_gemstash_version
        version = Gem::Version.new(Gemstash::Storage.metadata[:gemstash_version])
        return if Gem::Requirement.new("<= #{Gemstash::VERSION}").satisfied_by?(Gem::Version.new(version))
        raise Gemstash::CLI::Error.new(@cli, "Gemstash version is too old")
      end

      def pidfile_args
        ["--pidfile", gemstash_env.base_file("puma.pid")]
      end
    end
  end
end
