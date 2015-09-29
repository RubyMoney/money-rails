$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
ENV["RACK_ENV"] = "test"
require "gemstash"
require "dalli"
require "fileutils"
require "pathname"
require "support/db_helpers"
require "support/env_helpers"
require "support/exec_helpers"
require "support/file_helpers"
require "support/matchers"
require "support/simple_server"
require "support/test_gemstash_server"

TEST_BASE_PATH = File.expand_path("../../tmp/test_base", __FILE__)
FileUtils.mkpath(TEST_BASE_PATH) unless Dir.exist?(TEST_BASE_PATH)
TEST_CONFIG = Gemstash::Configuration.new(config: {
                                            :base_path => TEST_BASE_PATH
                                          })
Gemstash::Env.current = Gemstash::Env.new(TEST_CONFIG)

RSpec.configure do |config|
  config.around(:each) do |example|
    test_env.config = TEST_CONFIG unless test_env.config == TEST_CONFIG
    db = test_env.db

    db.transaction(:rollback => :always) do
      example.run
    end

    db.disconnect
  end

  config.before(:each) do
    test_env.cache_client.flush

    Pathname.new(TEST_BASE_PATH).children.each do |path|
      next if path.basename.to_s.end_with?(".db")
      path.rmtree
    end
  end

  config.after(:suite) do
    SimpleServer.join_all
    TestGemstashServer.join_all
  end

  config.include EnvHelpers
  config.include DBHelpers
  config.include ExecHelpers
  config.include FileHelpers
  config.raise_errors_for_deprecations!
end
