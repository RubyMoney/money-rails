$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
ENV["RACK_ENV"] = "test"
require "gemstash"
require "dalli"
require "fileutils"
require "support/db_helpers"
require "support/file_helpers"
require "support/matchers"
require "support/simple_server"

TEST_BASE_PATH = File.expand_path("../../tmp/test_base", __FILE__)
FileUtils.mkpath(TEST_BASE_PATH) unless Dir.exist?(TEST_BASE_PATH)
TEST_CONFIG = Gemstash::Configuration.new(config: {
                                            :base_path => TEST_BASE_PATH
                                          })

RSpec.configure do |config|
  config.around(:each) do |example|
    unless Gemstash::Env.config == TEST_CONFIG
      Gemstash::Env.config = TEST_CONFIG
    end

    db = Gemstash::Env.db

    db.transaction(:rollback => :always) do
      example.run
    end

    db.disconnect
  end

  config.before(:each) do
    Gemstash::Env.cache_client.flush
  end

  config.after(:suite) do
    SimpleServer.join_all
  end

  config.include DBHelpers
  config.include FileHelpers
  config.raise_errors_for_deprecations!
end
