require "spec_helper"
require "tempfile"

describe Gemstash::Logging do
  before do
    @logfile = Tempfile.create("logfile")
    Gemstash::Logging.setup_logger(@logfile)
  end
  after do
    Gemstash::Logging.reset
    # FileUtils.remove(@logfile)
  end

  it "Builds a logger in the right place" do
    expect(File.exist?(@logfile)).to be_truthy
  end

  it "Has a valid raw logger that is not stdout" do
    expect(Gemstash::Logging.raw_logger).not_to eq($stdout)
  end

  it "Can write using the formatted logger" do
    Gemstash::Logging.logger.error("a formatted message")
    Gemstash::Logging.reset # Close the logger so it flushes the content in
    expect(File.new(@logfile, "r").read).to include("ERROR - a formatted message")
  end

  it "Can write using the raw logger" do
    Gemstash::Logging.raw_logger.write("an unformatted message")
    Gemstash::Logging.reset # Close the logger so it flushes the content in
    expect(File.new(@logfile, "r").read).to match(/^an unformatted message$/)
  end

  it "Can puts using the raw logger" do
    Gemstash::Logging.raw_logger.puts("another unformatted message")
    Gemstash::Logging.reset # Close the logger so it flushes the content in
    expect(File.new(@logfile, "r").read).to match(/^another unformatted message$/)
  end
end
