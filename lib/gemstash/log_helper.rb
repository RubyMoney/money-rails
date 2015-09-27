require "logger"

module Gemstash
  #:nodoc:
  module Logging
    #:nodoc:
    def self.setup_logger
      logfile = Gemstash::Env.log_file
      log = File.new(logfile, "a+")
      $stderr.reopen(log)
      $stdout.reopen(log)
      $stderr.sync = true
      $stdout.sync = true

      @formatted_logger = Logger.new(logfile)

      @raw_logger = Logger.new(logfile, shift_age: 7, shift_size: 10_485_760)
      @raw_logger.formatter = proc do
        msg
      end
    end

    def self.formatted_logger
      @formatted_logger ||= Logger.new($stdout)
    end

    def self.wrapped_logger
      LoggerIOWrapper.new(@raw_logger)
    end

    def log
      Gemstash::Logging.formatted_logger
    end
  end

  #:nodoc:
  class LoggerIOWrapper < IO
    def initialize(logger)
      @log = logger
    end

    def write(str)
      @log.info str
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
