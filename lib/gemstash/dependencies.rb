require "cgi"
require "set"

module Gemstash
  #:nodoc:
  class Dependencies
    def initialize(web_helper = nil)
      @web_helper = web_helper || Gemstash::RubygemsWebHelper.new
    end

    def fetch(gems)
      Fetcher.new(gems, @web_helper).fetch
    end

    #:nodoc:
    class Fetcher
      def initialize(gems, web_helper)
        @gems = Set.new(gems)
        @web_helper = web_helper
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

        results = Gemstash::Env.db["
          SELECT rubygem.name,
                 version.number, version.platform,
                 dependency.rubygem_name, dependency.requirements
          FROM rubygems rubygem
          JOIN versions version
            ON version.rubygem_id = rubygem.id
          LEFT JOIN dependencies dependency
            ON dependency.version_id = version.id
          WHERE rubygem.name IN ?
            AND version.indexed = ?", @gems.to_a, true].to_a
        results.group_by {|r| r[:name] }.each do |gem, rows|
          requirements = rows.group_by {|r| [r[:number], r[:platform]] }

          value = requirements.map do |version, r|
            deps = r.map {|x| [x[:rubygem_name], x[:requirements]] }
            deps = [] if deps.size == 1 && deps.first.first.nil?

            {
              :name => gem,
              :number => version.first,
              :platform => version.last,
              :dependencies => deps
            }
          end

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
