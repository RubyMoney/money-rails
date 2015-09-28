require "gemstash"

threads 0, 16
port Gemstash::Env.config[:port]
workers 1
rackup Gemstash::Env.rackup
