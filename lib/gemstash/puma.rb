require "gemstash"

threads 0, 16
bind "tcp://#{Gemstash::Env.current.config[:host]}:#{Gemstash::Env.current.config[:port]}"
workers 1
rackup Gemstash::Env.current.rackup
