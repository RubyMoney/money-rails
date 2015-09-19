require "gemstash"
require "fileutils"
require "puma/cli"

module Gemstash
  class CLI
    #:nodoc:
    class Start
      def initialize(cli)
        @cli = cli
      end

      def run
        ensure_pidfile_path_exists if daemonize?
        Puma::CLI.new(args).run
      end

    private

      def daemonize?
        @cli.options[:daemonize]
      end

      def puma_config
        File.expand_path("../../puma.rb", __FILE__)
      end

      def pidfile_dir
        File.dirname(Gemstash::Env.pidfile)
      end

      def ensure_pidfile_path_exists
        return if Dir.exist?(pidfile_dir)
        FileUtils.mkpath(pidfile_dir)
      end

      def args
        ["--config", puma_config] + daemonize_args
      end

      def daemonize_args
        if daemonize?
          ["--daemon", "--pidfile", Gemstash::Env.pidfile]
        else
          []
        end
      end
    end
  end
end
