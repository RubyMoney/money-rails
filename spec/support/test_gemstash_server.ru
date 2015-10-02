require "gemstash"
use Rack::Deflater
use Gemstash::Env::RackMiddleware, $test_gemstash_server_env
use Gemstash::GemSource::RackMiddleware
run Gemstash::Web.new(gemstash_env: $test_gemstash_server_env)
