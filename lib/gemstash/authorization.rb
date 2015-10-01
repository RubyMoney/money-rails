require "set"

module Gemstash
  # Authorization mechanism to manipulate private gems.
  class Authorization
    VALID_PERMISSIONS = %w(push yank unyank).freeze

    def self.authorize(auth_key, permissions, db_helper = nil)
      raise "Authorization key is required!" if !auth_key || auth_key.strip.empty?
      raise "Permissions are required!" if !permissions || permissions.strip.empty?

      if permissions != "all"
        permissions.split(",").each do |permission|
          unless VALID_PERMISSIONS.include?(permission)
            raise "Invalid permission '#{permission}'"
          end
        end
      end

      db_helper ||= Gemstash::DBHelper.new
      db_helper.insert_or_update_authorization(auth_key, permissions)
    end

    def self.[](auth_key, db_helper = nil)
      db_helper ||= Gemstash::DBHelper.new
      auth_row = db_helper.find_authorization(auth_key)
      new(auth_row[:auth_key], auth_row[:permissions]) if auth_row
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
