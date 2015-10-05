require "set"

module Gemstash
  # Authorization mechanism to manipulate private gems.
  class Authorization
    extend Gemstash::Env::Helper
    extend Gemstash::Logging
    VALID_PERMISSIONS = %w(push yank unyank).freeze

    def self.authorize(auth_key, permissions, db_helper = nil)
      raise "Authorization key is required!" if !auth_key || auth_key.strip.empty?
      raise "Permissions are required!" if !permissions || permissions.empty?

      unless permissions == "all"
        permissions.each do |permission|
          unless VALID_PERMISSIONS.include?(permission)
            raise "Invalid permission '#{permission}'"
          end
        end

        permissions = permissions.join(",")
      end

      db_helper ||= Gemstash::DBHelper.new
      db_helper.insert_or_update_authorization(auth_key, permissions)
      gemstash_env.cache.invalidate_authorization(auth_key)
      log.info "Authorization '#{auth_key}' updated with access to '#{permissions}'"
    end

    def self.remove(auth_key, db_helper = nil)
      db_helper ||= Gemstash::DBHelper.new
      auth_row = db_helper.find_authorization(auth_key)
      return unless auth_row
      db_helper.delete_authorization(auth_key)
      gemstash_env.cache.invalidate_authorization(auth_key)
      log.info "Authorization '#{auth_key}' with access to '#{auth_row[:permissions]}' removed"
    end

    def self.[](auth_key, db_helper = nil)
      cached_auth = gemstash_env.cache.authorization(auth_key)
      return cached_auth if cached_auth
      db_helper ||= Gemstash::DBHelper.new
      auth_row = db_helper.find_authorization(auth_key)

      if auth_row
        auth = new(auth_row[:auth_key], auth_row[:permissions])
        gemstash_env.cache.set_authorization(auth_row[:auth_key], auth)
        auth
      end
    end

    def initialize(auth_key, permissions)
      @auth_key = auth_key
      @all = permissions == "all"
      @permissions = Set.new(permissions.split(","))
    end

    def all?
      @all
    end

    def push?
      all? || @permissions.include?("push")
    end

    def yank?
      all? || @permissions.include?("yank")
    end

    def unyank?
      all? || @permissions.include?("unyank")
    end
  end
end
