require "cgi"
require "set"

module Gemstash
  #:nodoc:
  class Dependencies
    def initialize(web_helper = nil, db_helper = nil)
      @web_helper = web_helper || Gemstash::WebHelper.new
      @db_helper = db_helper || Gemstash::DBHelper.new
    end

    def fetch(gems)
      Fetcher.new(gems, @web_helper, @db_helper).fetch
    end

    #:nodoc:
    class Fetcher
      def initialize(gems, web_helper, db_helper)
        @gems = Set.new(gems)
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
        Gemstash::Env.cache.dependencies(@gems) do |gem, value|
          @gems.delete(gem)
          @dependencies += value
        end
      end

      def fetch_from_database
        return if done?
        puts "Querying dependencies: #{@gems.to_a.join(", ")}"

        @db_helper.find_dependencies(@gems) do |gem, value|
          @gems.delete(gem)
          Gemstash::Env.cache.set_dependency(gem, value)
          @dependencies += value
        end
      end

      def fetch_from_web
        return if done?
        puts "Fetching dependencies: #{@gems.to_a.join(", ")}"
        gems_param = @gems.map {|gem| CGI.escape(gem) }.join(",")
        fetched = @web_helper.get("/api/v1/dependencies?gems=#{gems_param}")
        fetched = Marshal.load(fetched).group_by {|r| r[:name] }

        fetched.each do |gem, result|
          @gems.delete(gem)
          Gemstash::Env.cache.set_dependency(gem, result)
          @dependencies += result
        end
      end

      def cache_missing
        @gems.each do |gem|
          Gemstash::Env.cache.set_dependency(gem, [])
        end
      end
    end
  end
end
