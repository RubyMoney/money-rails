require "logger"
require "puma/events"

module Gemstash
  #:nodoc:
  module Logging
    def log
      Gemstash::Logging.logger
    end

    def self.setup_logger(logfile)
      @logging_sink = LoggingSink.new(logfile)
    end

    def self.logger
      return @logging_sink.logger if @logging_sink
      Logger.new($stdout)
    end

    def self.raw_logger
      return @logging_sink.raw_logger if @logging_sink
      $stdout
    end

    def self.reset
      @logging_sink.close if @logging_sink
      @logging_sink = nil
    end

    #:nodoc:
    class PumaLogger
      def self.puma_events
        Puma::Events.new(for_stdout, for_stderr)
      end

      def self.for_stdout
        new(Logger::INFO)
      end

      def self.for_stderr
        new(Logger::ERROR)
      end

      def initialize(level)
        @level = level
      end

      def sync=(_value)
      end

      def write(message)
        Gemstash::Logging.logger.add(@level, message)
      end

      def puts(message)
        Gemstash::Logging.logger.add(@level, message)
      end
    end

    #:nodoc:
    module LoggerPatch
      def log_device
        @logdev
      end
    end

    #:nodoc:
    module IOCompatible
      def sync=(_value)
      end

      def puts(msg)
        write("#{msg}\n")
      end
    end

    #:nodoc:
    class LoggingSink
      Logger.include(Gemstash::Logging::LoggerPatch)
      Logger::LogDevice.include(Gemstash::Logging::IOCompatible)

      attr_accessor :logger

      def initialize(logfile)
        @logger = Logger.new(logfile)
        @logger.level = Logger::INFO
        @logger.datetime_format = "%d/%b/%Y:%H:%M:%S %z"
        @logger.formatter = proc do |severity, datetime, _progname, msg|
          "[#{datetime}] - #{severity} - #{msg}\n"
        end
        @raw_logger = @logger.log_device
      end

      def raw_logger
        @logger.log_device
      end

      def close
        @logger.close
      end
    end
  end

  #
  # Unused for now, this is how a rack middleware looks like.
  # This should be used later to normalize logging message format
  #
  class LoggerMiddleware
    def initialize(app, logger)
      @app = app
      @logger = logger
    end

    def call(env)
      env["rack.logger"] = @logger
      @app.call(env)
    end
  end
end
