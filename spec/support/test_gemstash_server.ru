require "gemstash"
use Rack::Deflater
run Gemstash::Web.new(gemstash_env: $test_gemstash_server_env)
