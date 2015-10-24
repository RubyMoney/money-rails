require "gemstash"

module Gemstash
  # Class that supports yanking a gem from the private repository of gems.
  class GemYanker
    include Gemstash::Env::Helper

    # This error is thrown when yanking a non-existing gem name.
    class UnknownGemError < StandardError
    end

    # This error is thrown when yanking a non-existing gem version.
    class UnknownVersionError < StandardError
    end

    # This error is thrown when yanking an already yanked gem version.
    class YankedVersionError < StandardError
    end

    def initialize(auth_key, gem_name, version)
      @auth_key = auth_key
      @gem_name = gem_name
      @version = version
      @db_helper = Gemstash::DBHelper.new
    end

    def yank
      check_auth
      update_database
      invalidate_cache
    end

  private

    def check_auth
      raise Gemstash::NotAuthorizedError, "Authorization key required" if @auth_key.to_s.strip.empty?
      auth = Authorization[@auth_key]
      raise Gemstash::NotAuthorizedError, "Authorization key is invalid" unless auth
      raise Gemstash::NotAuthorizedError, "Authorization key doesn't have yank access" unless auth.yank?
    end

    def update_database
      gemstash_env.db.transaction do
        gem_id = @db_helper.find_rubygem_id(@gem_name)
        raise UnknownGemError, "Cannot yank an unknown gem!" unless gem_id
      end
    end

    def invalidate_cache
    end
  end
end
