require "gemstash"

module Gemstash
  # Class that supports yanking a gem from the private repository of gems.
  class GemYanker
    def initialize(auth_key, gem_name, version)
      @auth_key = auth_key
    end

    def yank
      check_auth
    end

  private

    def check_auth
      raise Gemstash::NotAuthorizedError, "Authorization key required" if @auth_key.to_s.strip.empty?
      auth = Authorization[@auth_key]
      raise Gemstash::NotAuthorizedError, "Authorization key is invalid" unless auth
      raise Gemstash::NotAuthorizedError, "Authorization key doesn't have yank access" unless auth.yank?
    end
  end
end
