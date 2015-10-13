require "gemstash"

threads 0, 16
bind "#{Gemstash::Env.current.config[:bind]}"
workers 1
rackup Gemstash::Env.current.rackup
