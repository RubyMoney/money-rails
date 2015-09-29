require "gemstash"
require "logger"

#:nodoc:
module Gemstash
  #:nodoc:
  class Strategies
    def self.from_config(config)
      # we will need to make this logic more complicated later when we have more complex
      # strategies, for now we are good just returning
      strategies = { "redirection" => Gemstash::RedirectionStrategy,
                     "caching"     => Gemstash::CachingStrategy }

      strategies.fetch(config[:strategy]).new
    end
  end

  #
  # Basic web serving strategy that will just redirect the requested to rubygems
  #
  class RedirectionStrategy
    def initialize(web_helper: nil)
      @web_helper = web_helper || Gemstash::WebHelper.new
    end

    def serve_root(app)
      app.cache_control :public, :max_age => 31_536_000
      app.redirect @web_helper.url
    end

    def serve_marshal(app, id:)
      app.redirect @web_helper.url("/quick/Marshal.4.8/#{id}")
    end

    def serve_actual_gem(app, id:)
      app.redirect @web_helper.url("/fetch/actual/gem/#{id}")
    end

    def serve_gem(app, id:)
      app.redirect @web_helper.url("/gems/#{id}")
    end

    def serve_latest_specs(app)
      app.redirect @web_helper.url("/latest_specs.4.8.gz")
    end

    def serve_specs(app)
      app.redirect @web_helper.url("/specs.4.8.gz")
    end

    def serve_prerelease_specs(app)
      app.redirect @web_helper.url("/prerelease_specs.4.8.gz")
    end
  end

  #
  # Simple layer gem caching strategy
  #
  # This object will serve gems, fetching and caching them locally
  # to then return them to the requester, along with the original
  # headers
  class CachingStrategy < RedirectionStrategy
    def initialize(storage: nil, web_helper: nil)
      super(web_helper: web_helper)
      @storage = storage || Gemstash::GemStorage.new
      puts "Using a caching strategy"
    end

    def serve_gem(app, id:)
      gem = fetch_gem(id)
      app.headers.update(gem.headers)
      gem.content
    rescue Gemstash::WebError => e
      app.halt e.code
    end

    def fetch_gem(id)
      gem = @storage.get(id)
      if gem.exist?
        puts "Gem #{id} exists, returning cached"
        gem
      else
        puts "Gem #{id} is not cached, fetching"
        @web_helper.get("/gems/#{id}") do |body, headers|
          gem.save(headers, body)
        end
      end
    end
  end
end
