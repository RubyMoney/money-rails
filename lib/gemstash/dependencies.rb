require "cgi"
require "set"

module Gemstash
  #:nodoc:
  class Dependencies
    def self.for_private(db_helper: nil)
      db_helper ||= Gemstash::DBHelper.new
      new(scope: "private", db_helper: db_helper)
    end

    def self.for_upstream(web_helper)
      new(scope: "upstream/#{web_helper.url}", web_helper: web_helper)
    end

    def initialize(scope: nil, web_helper: nil, db_helper: nil)
      @scope = scope
      @web_helper = web_helper
      @db_helper = db_helper
    end

    def fetch(gems)
      Fetcher.new(gems, @scope, @web_helper, @db_helper).fetch
    end

    #:nodoc:
    class Fetcher
      include Gemstash::Env::Helper
      include Gemstash::Logging

      def initialize(gems, scope, web_helper, db_helper)
        @gems = Set.new(gems)
        @scope = scope
        @web_helper = web_helper
        @db_helper = db_helper
        @dependencies = []
      end

      def fetch
        fetch_from_cache
        fetch_from_database
        fetch_from_web
        cache_missing
        @dependencies
      end

    private

      def done?
        @gems.empty?
      end

      def fetch_from_cache
        gemstash_env.cache.dependencies(@scope, @gems) do |gem, value|
          @gems.delete(gem)
          @dependencies += value
        end
      end

      def fetch_from_database
        return if done?
        return unless @db_helper
        log.info "Querying dependencies: #{@gems.to_a.join(", ")}"

        @db_helper.find_dependencies(@gems) do |gem, value|
          @gems.delete(gem)
          gemstash_env.cache.set_dependency(@scope, gem, value)
          @dependencies += value
        end
      end

      def fetch_from_web
        return if done?
        return unless @web_helper
        log.info "Fetching dependencies: #{@gems.to_a.join(", ")}"
        gems_param = @gems.map {|gem| CGI.escape(gem) }.join(",")
        fetched = @web_helper.get("/api/v1/dependencies?gems=#{gems_param}")
        fetched = Marshal.load(fetched).group_by {|r| r[:name] }

        fetched.each do |gem, result|
          @gems.delete(gem)
          gemstash_env.cache.set_dependency(@scope, gem, result)
          @dependencies += result
        end
      end

      def cache_missing
        @gems.each do |gem|
          gemstash_env.cache.set_dependency(@scope, gem, [])
        end
      end
    end
  end
end
