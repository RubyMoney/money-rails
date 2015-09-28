require "logger"

module Gemstash
  #:nodoc:
  module Logging

    module LoggerMixin
      def log_device
        @logdev
      end
    end

    module IOCompatible
      def sync=(_value)
      end

      def puts(msg)
        write("#{msg}\n")
      end
    end

    #:nodoc:
    def self.setup_logger
      logfile = Gemstash::Env.log_file
      #This is for the events
      # log = File.new(logfile, "a+")
      # $stderr.reopen(log)
      # $stdout.reopen(log)
      # $stderr.sync = true
      # $stdout.sync = true
      Logger.include Gemstash::Logging::LoggerMixin
      Logger::LogDevice.include Gemstash::Logging::IOCompatible

      @formatted_logger = Logger.new(logfile)
      @formatted_logger.formatter = proc do |severity, datetime, _progname, msg|
        formatted_date = datetime.strftime("%d/%b/%Y:%H:%M:%S %z")
        "[#{formatted_date}] - #{severity} - #{msg}\n"
      end
      @raw_logger = @formatted_logger.log_device

      # @raw_logger = Logger.new(logfile, shift_age: 1, shift_size: 10_485_760)
      # @raw_logger.formatter = proc do |_severity, _datetime, _progname, msg|
      #   msg
      # end
    end

    def self.formatted_logger
      @formatted_logger || Logger.new("/dev/null")
    end

    def self.wrapped_logger
      @raw_logger ||$stdout
    end

    def log
      Gemstash::Logging.formatted_logger
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
