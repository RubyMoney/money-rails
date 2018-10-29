require "gemstash"

threads 0, Gemstash::Env.current.config[:puma_threads].to_i
bind Gemstash::Env.current.config[:bind].to_s
workers Gemstash::Env.current.config[:puma_workers].to_i unless RUBY_PLATFORM == "java"
rackup Gemstash::Env.current.rackup
