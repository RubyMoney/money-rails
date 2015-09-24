require "gemstash"

threads Gemstash::Env.config[:min_threads], Gemstash::Env.config[:max_threads]
port Gemstash::Env.config[:port]
workers Gemstash::Env.config[:workers]
rackup Gemstash::Env.rackup
