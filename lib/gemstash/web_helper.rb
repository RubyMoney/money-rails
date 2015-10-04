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
    include Gemstash::Env::Helper

    def initialize(http_client:, server_url: nil)
      @client = http_client
      @server_url = server_url || env.config[:rubygems_url]
    end

    def get(path)
      response = @client.get(path) do |req|
        req.options.open_timeout = 2
      end

      raise WebError.new(response.body, response.status) unless response.success?

      if block_given?
        yield(response.body, response.headers)
      else
        response.body
      end
    end

    def url(path = nil, params = nil)
      params = "?#{params}" if !params.nil? && !params.empty?
      "#{@server_url}#{path}#{params}"
    end
  end

  #:nodoc:
  class HTTPClientBuilder
    def for(server_url)
      Faraday.new(server_url) do |config|
        config.use FaradayMiddleware::FollowRedirects
        config.adapter :net_http
      end
    end
  end
end
