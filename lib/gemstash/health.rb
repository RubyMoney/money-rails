require "gemstash"
require "date"
require "server_health_check_rack"
require "sequel"

module Gemstash
  # This module contains the logic used to supply a health monitor for
  # Gemstash. You can access the health monitor at the /health endpoint.
  module Health
    # This check can be used if you don't want to read or write content during a
    # health check.
    def self.heartbeat
      true
    end

    def self.check_storage_read
      if check_storage_write
        content = Gemstash::Storage.for("health").resource("test").content(:example)
        content =~ /\Acontent-\d+\z/
      end
    end

    def self.check_storage_write
      resource = Gemstash::Storage.for("health").resource("test")
      resource.save(example: "content-#{Time.now.to_i}")
      true
    end

    def self.check_db_read
      result = Gemstash::Env.current.db[:rubygems].where(name: "testing_db_read").count
      result.is_a?(Numeric)
    end

    def self.check_db_write
      Gemstash::Env.current.db.transaction do
        health_tests = Gemstash::Env.current.db[:health_tests]
        health_tests.truncate
        health_tests.insert(string: "test_string")
        # We don't want to actually write to the database
        raise Sequel::Rollback
      end

      true
    end

    ServerHealthCheckRack::Checks.check("heartbeat") { Gemstash::Health.heartbeat }
    ServerHealthCheckRack::Checks.check("storage_read") { Gemstash::Health.check_storage_read }
    ServerHealthCheckRack::Checks.check("storage_write") { Gemstash::Health.check_storage_write }
    ServerHealthCheckRack::Checks.check("db_read") { Gemstash::Health.check_db_read }
    ServerHealthCheckRack::Checks.check("db_write") { Gemstash::Health.check_db_write }
    RackMiddleware = ServerHealthCheckRack::Middleware
  end
end
