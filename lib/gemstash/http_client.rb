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
    def self.for(server_url)
      client = Faraday.new(server_url) do |config|
        config.use FaradayMiddleware::FollowRedirects
        config.adapter :net_http
      end

      new(client)
    end

    def initialize(client = nil)
      @client = client
    end

    def get(path)
      response = @client.get(path) do |req|
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
