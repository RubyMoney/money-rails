require "gemstash"
require "dalli"

module Gemstash
  #:nodoc:
  class Env
    def self.min_threads
      0
    end

    def self.max_threads
      16
    end

    def self.port
      9292
    end

    def self.workers
      1
    end

    def self.rackup
      File.expand_path("../config.ru", __FILE__)
    end

    def self.cache
      @cache ||= Gemstash::Cache.new(memcached_client)
    end

    def self.memcached_client
      @memcached_client ||= Dalli::Client.new
    end

    def self.rubygems_url
      "https://www.rubygems.org"
    end
  end
end
