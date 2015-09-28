require "logger"

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
      @loggingasink = nil
    end

    #:nodoc:
    module LoggerMixin
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
      Logger.include(Gemstash::Logging::LoggerMixin)
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

  #:nodoc:
  class MyLoggerMiddleware
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
