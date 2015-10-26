require "gemstash"

# Helper to ensure the test Gemstash environment is set.
module EnvHelpers
  def test_env
    if Thread.current[:test_gemstash_env_set]
      Gemstash::Env.current
    else
      Thread.current[:test_gemstash_env_set] = true
      Gemstash::Env.current = Gemstash::Env.new(TEST_CONFIG, db: TEST_DB)
    end
  end
end
