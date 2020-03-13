# frozen_string_literal: true

require "set"

module Gemstash
  # An action was not authorized and should cause the server to send a 401.
  class NotAuthorizedError < StandardError
  end

  # Authorization mechanism to manipulate private gems.
  class Authorization
    extend Gemstash::Env::Helper
    extend Gemstash::Logging
    VALID_PERMISSIONS = %w[push yank fetch].freeze

    def self.authorize(auth_key, permissions)
      raise "Authorization key is required!" if auth_key.to_s.strip.empty?
      raise "Permissions are required!" if permissions.to_s.empty?

      unless permissions == "all"
        permissions.each do |permission|
          raise "Invalid permission '#{permission}'" unless VALID_PERMISSIONS.include?(permission)
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

    def self.check(auth_key, permission)
      raise NotAuthorizedError, "Authorization key required" if auth_key.to_s.strip.empty?

      auth = self[auth_key]
      raise NotAuthorizedError, "Authorization key is invalid" unless auth
      raise NotAuthorizedError, "Authorization key doesn't have #{permission} access" unless auth.can?(permission)
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

    def can?(permission)
      raise "Invalid permission '#{permission}'" unless VALID_PERMISSIONS.include?(permission)

      all? || @permissions.include?(permission)
    end

    def all?
      @all
    end

    def push?
      can?("push")
    end

    def yank?
      can?("yank")
    end

    def fetch?
      can?("fetch")
    end
  end
end
