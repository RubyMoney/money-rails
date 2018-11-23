# frozen_string_literal: true

require "gemstash"
use Rack::Deflater
use Gemstash::Env::RackMiddleware, $test_gemstash_server_env
use Gemstash::GemSource::RackMiddleware
use Gemstash::Health::RackMiddleware
run Gemstash::Web.new(gemstash_env: $test_gemstash_server_env)
