require "gemstash"
require "faraday"
require "faraday_middleware"

module Gemstash
  #:nodoc:
  class WebError < StandardError
    attr_reader :code

    def initialize(message, code)
      @code = code
      super(message)
    end
  end

  #:nodoc:
  class HTTPClient
    DEFAULT_USER_AGENT = "Gemstash #{Gemstash::VERSION}"

    def self.for(upstream)
      client = Faraday.new(upstream.to_s) do |config|
        config.use FaradayMiddleware::FollowRedirects
        config.adapter :net_http
      end
      user_agent = DEFAULT_USER_AGENT
      user_agent << " - #{upstream.user_agent}" unless upstream.user_agent.to_s.empty?

      new(client, user_agent: user_agent)
    end

    def initialize(client = nil, user_agent: nil)
      @client = client
      @user_agent = user_agent || DEFAULT_USER_AGENT
    end

    def get(path)
      response = @client.get(path) do |req|
        req.headers["User-Agent"] = @user_agent
        req.options.open_timeout = 2
      end

      raise Gemstash::WebError.new(response.body, response.status) unless response.success?

      if block_given?
        yield(response.body, response.headers)
      else
        response.body
      end
    end
  end
end
