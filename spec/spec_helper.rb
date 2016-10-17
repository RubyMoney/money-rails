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
require "support/in_process_exec"
require "support/log_helpers"
require "support/matchers"
require "support/simple_server"
require "support/slow_simple_server"
require "support/test_gemstash_server"

TEST_BASE_PATH = File.expand_path("../../tmp/test_base", __FILE__)
FileUtils.mkpath(TEST_BASE_PATH) unless Dir.exist?(TEST_BASE_PATH)
Pathname.new(TEST_BASE_PATH).children.each(&:rmtree)
TEST_LOG_FILE = File.join(TEST_BASE_PATH, "server.log")
TEST_CONFIG = Gemstash::Configuration.new(config: {
                                            :base_path => TEST_BASE_PATH
                                          })
Gemstash::Env.current = Gemstash::Env.new(TEST_CONFIG)
Thread.current[:test_gemstash_env_set] = true
TEST_DB = Gemstash::Env.current.db
Sequel::Model.db = TEST_DB

RSpec.configure do |config|
  config.around(:each) do |example|
    test_env.config = TEST_CONFIG unless test_env.config == TEST_CONFIG

    # Some integration specs will fail in a transaction, so allow disabling
    if example.metadata[:db_transaction] == false
      example.run
    else
      TEST_DB.transaction(:rollback => :always) do
        example.run
      end
    end

    TEST_DB.disconnect

    # If a spec has no transaction, delete the DB, and force recreate/migrate to ensure it is clean
    if example.metadata[:db_transaction] == false
      File.delete(File.join(TEST_BASE_PATH, "gemstash.db"))
      Gemstash::Env.migrate(TEST_DB)
    end
  end

  config.before(:each) do
    test_env.cache_client.flush
    Gemstash::Logging.reset

    Pathname.new(TEST_BASE_PATH).children.each do |path|
      next if path.basename.to_s.end_with?(".db")
      path.rmtree
    end

    Gemstash::Logging.setup_logger(TEST_LOG_FILE)
  end

  config.after(:suite) do
    SimpleServer.join_all
    TestGemstashServer.join_all
  end

  # Tag examples with focus: true to run only those
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.include EnvHelpers
  config.include DBHelpers
  config.include ExecHelpers
  config.include FileHelpers
  config.include LogHelpers
  config.raise_errors_for_deprecations!
end
