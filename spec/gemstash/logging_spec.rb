require "spec_helper"
require "fileutils"
require "tempfile"

describe Gemstash::Logging do
  before do
    @logfile = Tempfile.create("logfile")
    Gemstash::Logging.setup_logger(@logfile)
  end

  after do
    Gemstash::Logging.reset
    FileUtils.remove(@logfile)
  end

  it "builds a logger in the right place" do
    expect(File.exist?(@logfile)).to be_truthy
  end

  it "can write using the formatted logger" do
    Gemstash::Logging.logger.error("a formatted message")
    Gemstash::Logging.reset # Close the logger so it flushes the content in
    expect(File.read(@logfile)).to include("ERROR - a formatted message")
  end

  it "won't add multiple lines when logging with newlines" do
    Gemstash::Logging.logger.info("a message with a newline\n")
    Gemstash::Logging.reset # Close the logger so it flushes the content in
    log_contents = File.read(@logfile)
    expect(log_contents).to include("a message with a newline\n")
    expect(log_contents).to_not include("a formatted message\n\n")
  end
end

describe Gemstash::Logging::StreamLogger do
  before do
    @logfile = Tempfile.create("logfile")
    Gemstash::Logging.setup_logger(@logfile)
  end

  after do
    Gemstash::Logging.reset
    FileUtils.remove(@logfile)
  end

  let(:logger) { Gemstash::Logging::StreamLogger.new(Logger::INFO) }
  let(:error_logger) { Gemstash::Logging::StreamLogger.new(Logger::ERROR) }

  it "responds to flush" do
    expect(logger).to respond_to(:flush)
  end

  it "response to sync=" do
    expect(logger).to respond_to(:sync=)
  end

  it "logs with write" do
    logger.write("a message with write")
    Gemstash::Logging.reset # Close the logger so it flushes the content in
    expect(File.read(@logfile)).to include("a message with write")
  end

  it "logs with puts" do
    logger.puts("a message with puts")
    Gemstash::Logging.reset # Close the logger so it flushes the content in
    expect(File.read(@logfile)).to include("a message with puts")
  end

  it "logs with the level provided" do
    logger.puts("an info message")
    error_logger.puts("an error message")
    Gemstash::Logging.reset # Close the logger so it flushes the content in
    log_contents = File.read(@logfile)
    expect(log_contents).to include("INFO - an info message")
    expect(log_contents).to include("ERROR - an error message")
  end
end
