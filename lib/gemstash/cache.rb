module Gemstash
  #:nodoc:
  class Cache
    EXPIRY = 30 * 60

    def initialize(memcached_client)
      @memcached_client = memcached_client
    end

    def dependencies(gems)
      keys = gems.map {|g| "deps/v1/#{g}" }

      @memcached_client.get_multi(keys) do |key, value|
        yield(key.sub("deps/v1/", ""), value)
      end
    end

    def set_dependency(gem, value)
      @memcached_client.set("deps/v1/#{gem}", value, EXPIRY)
    end
  end
end
