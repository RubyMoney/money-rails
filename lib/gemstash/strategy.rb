require "faraday"
require "faraday_middleware"

#:nodoc:
module Gemstash
  #
  # Basic web serving strategy that will just redirect the requested to rubygems
  #
  class RedirectionStrategy
    def initialize(web_helper: nil)
      @web_helper = web_helper || Gemstash::RubygemsWebHelper.new
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
    def initialize(storage:, web_helper: nil, gem_fetcher: nil)
      super(web_helper: web_helper)
      @storage = storage
      @gem_fetcher = gem_fetcher || GemFetcher.new
    end

    def serve_gem(app, id:)
      gem = fetch_gem(id)
      app.headers.update(gem.headers)
      gem.content
    rescue GemNotFoundError
      app.halt 404
    end

    def fetch_gem(id)
      gem = @storage.get(id)
      fetched_gem = @gem_fetcher.fetch(id)
      gem.save(fetched_gem.headers, fetched_gem.body)
    end
  end

  #
  # Simple client that knows how to fetch a gem file following redirections
  #
  class GemFetcher
    def initialize(http_client: nil, server_url: nil)
      @client = http_client
      @client ||= Faraday.new(server_url || Gemstash::Env.rubygems_url) do |c|
        c.use FaradayMiddleware::FollowRedirects
        c.adapter :net_http
      end
    end

    def fetch(id)
      response = @client.get("/gems/#{id}") do |req|
        req.options.open_timeout = 2
      end
      raise GemNotFoundError, id if response.status == 404
      FetchedGem.new(response.headers, response.body)
    end
  end

  FetchedGem = Struct.new(:headers, :body)

  class GemNotFoundError < StandardError; end
end
