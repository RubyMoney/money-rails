require "cgi"

module Gemstash
  #:nodoc:
  class Dependencies
    def initialize(web_helper = nil)
      @web_helper = web_helper || Gemstash::RubygemsWebHelper.new
    end

    def fetch(gems)
      gems = gems.dup
      dependencies = []

      Gemstash::Env.cache.dependencies(gems) do |gem, value|
        gems.delete(gem)
        dependencies += value
      end

      unless gems.empty?
        puts "Fetching dependencies: #{gems.join(", ")}"
        fetched = Marshal.load(external_fetch(gems)).group_by {|r| r[:name] }

        fetched.each do |gem, result|
          gems.delete(gem)
          Gemstash::Env.cache.set_dependency(gem, result)
          dependencies += result
        end

        gems.each do |gem|
          Gemstash::Env.cache.set_dependency(gem, [])
        end
      end

      dependencies
    end

  private

    def external_fetch(gems)
      gems_param = gems.map {|gem| CGI.escape(gem) }.join(",")
      @web_helper.get("/api/v1/dependencies?gems=#{gems_param}")
    end
  end
end
