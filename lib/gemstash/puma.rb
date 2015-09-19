require "gemstash"

threads Gemstash::Env.min_threads, Gemstash::Env.max_threads
port Gemstash::Env.port
workers Gemstash::Env.workers
rackup Gemstash::Env.rackup
