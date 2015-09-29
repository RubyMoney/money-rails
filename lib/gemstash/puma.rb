require "gemstash"

threads 0, 16
port Gemstash::Env.current.config[:port]
workers 1
rackup Gemstash::Env.current.rackup
