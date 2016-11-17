require "gemstash"

threads 0, Gemstash::Env.current.config[:puma_threads].to_i
bind Gemstash::Env.current.config[:bind].to_s
workers 1
rackup Gemstash::Env.current.rackup
