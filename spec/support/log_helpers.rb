#:nodoc:
module LogHelpers
  def the_log
    # Close the logger so it flushes the content
    Gemstash::Logging.reset
    result = File.read(TEST_LOG_FILE)
    Gemstash::Logging.setup_logger(TEST_LOG_FILE)
    result
  end
end
