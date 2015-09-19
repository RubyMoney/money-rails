require "cgi"

module Gemstash
  #:nodoc:
  class Dependencies
    EXPIRY = 30 * 60

    def initialize(web_helper = nil)
      @web_helper = web_helper || Gemstash::RubygemsWebHelper.new
    end

    def fetch(gems)
      dependencies = []
      keys = gems.map {|g| "deps/v1/#{g}" }

      Gemstash::Env.memcached_client.get_multi(keys) do |key, value|
        keys.delete(key)
        dependencies += value
      end

      unless keys.empty?
        gems = keys.map {|g| g.gsub("deps/v1/", "") }
        puts "Fetching dependencies: #{gems.join(", ")}"
        fetched = Marshal.load(external_fetch(gems)).group_by {|r| r[:name] }

        fetched.each do |gem, result|
          key = "deps/v1/#{gem}"
          keys.delete(key)
          Gemstash::Env.memcached_client.set(key, result, EXPIRY)
          dependencies += result
        end

        keys.each do |key|
          Gemstash::Env.memcached_client.set(key, [], EXPIRY)
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
