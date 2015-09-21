$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
ENV["RACK_ENV"] = "test"
require "gemstash"
require "dalli"
require "fileutils"
require "support/db_helpers"
require "support/matchers"

TEST_BASE_PATH = File.expand_path("../../tmp/test_base", __FILE__)
FileUtils.mkpath(TEST_BASE_PATH) unless Dir.exist?(TEST_BASE_PATH)
TEST_CONFIG = Gemstash::Env::DEFAULT_CONFIG.merge(
  :base_path => TEST_BASE_PATH
).freeze

RSpec.configure do |config|
  config.around(:each) do |example|
    unless Gemstash::Env.config == TEST_CONFIG
      Gemstash::Env.config = TEST_CONFIG
    end

    Gemstash::Env.db.transaction(:rollback => :always) do
      example.run
    end

    Gemstash::Env.db.disconnect
  end

  config.before(:each) do
    Gemstash::Env.cache_client.flush
  end

  config.include DBHelpers
  config.raise_errors_for_deprecations!
end
