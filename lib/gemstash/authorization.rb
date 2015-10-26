require "set"

module Gemstash
  # Authorization mechanism to manipulate private gems.
  class Authorization
    extend Gemstash::Env::Helper
    extend Gemstash::Logging
    VALID_PERMISSIONS = %w(push yank unyank).freeze

    def self.authorize(auth_key, permissions)
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

      Gemstash::DB::Authorization.insert_or_update(auth_key, permissions)
      gemstash_env.cache.invalidate_authorization(auth_key)
      log.info "Authorization '#{auth_key}' updated with access to '#{permissions}'"
    end

    def self.remove(auth_key)
      record = Gemstash::DB::Authorization[auth_key: auth_key]
      return unless record
      record.destroy
      gemstash_env.cache.invalidate_authorization(auth_key)
      log.info "Authorization '#{auth_key}' with access to '#{record.permissions}' removed"
    end

    def self.[](auth_key)
      cached_auth = gemstash_env.cache.authorization(auth_key)
      return cached_auth if cached_auth
      record = Gemstash::DB::Authorization[auth_key: auth_key]

      if record
        auth = new(record)
        gemstash_env.cache.set_authorization(record.auth_key, auth)
        auth
      end
    end

    def initialize(record)
      @auth_key = record.auth_key
      @all = record.permissions == "all"
      @permissions = Set.new(record.permissions.split(","))
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
