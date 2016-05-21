require "gemstash"

threads 0, 16
bind Gemstash::Env.current.config[:bind].to_s
workers 1
rackup Gemstash::Env.current.rackup
