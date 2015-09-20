require "lru_redux"

module Gemstash
  #:nodoc:
  class Cache
    EXPIRY = 30 * 60

    def initialize(client)
      @client = client
    end

    def dependencies(gems)
      keys = gems.map {|g| "deps/v1/#{g}" }

      @client.get_multi(keys) do |key, value|
        yield(key.sub("deps/v1/", ""), value)
      end
    end

    def set_dependency(gem, value)
      @client.set("deps/v1/#{gem}", value, EXPIRY)
    end
  end

  #:nodoc:
  class LruReduxClient
    MAX_SIZE = 500
    EXPIRY = Gemstash::Cache::EXPIRY

    def initialize
      @cache = LruRedux::TTL::ThreadSafeCache.new MAX_SIZE, EXPIRY
    end

    def alive!
      true
    end

    def flush
      @cache.clear
    end

    def get_multi(keys)
      keys.each do |key|
        found = true
        # Atomic fetch... don't rely on nil meaning missing
        value = @cache.fetch(key) { found = false }
        next unless found
        yield(key, value)
      end
    end

    def set(key, value, expiry)
      @cache[key] = value
    end
  end
end
