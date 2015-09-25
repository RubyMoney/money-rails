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
  class WebHelper
    def initialize(http_client: nil, server_url: nil)
      @server_url = server_url || Gemstash::Env.config[:rubygems_url]
      @client = http_client || Faraday.new(@server_url) do |config|
        config.use FaradayMiddleware::FollowRedirects
        config.adapter :net_http
      end
    end

    def get(path)
      response = @client.get(path) do |req|
        req.options.open_timeout = 2
      end

      if response.success?
        response.body
      else
        raise WebError.new(response.body, response.status)
      end
    end

    def url(path = nil)
      "#{@server_url}#{path}"
    end
  end
end
