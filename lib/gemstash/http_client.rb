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
  class ConnectionError < WebError
    def initialize(message)
      super(message, 502) # Bad Gateway
    end
  end

  #:nodoc:
  class HTTPClient
    include Gemstash::Logging

    DEFAULT_USER_AGENT = "Gemstash/#{Gemstash::VERSION}".freeze

    def self.for(upstream, timeout = 20)
      client = Faraday.new(upstream.to_s) do |config|
        config.use FaradayMiddleware::FollowRedirects
        config.adapter :net_http
        config.options.timeout = timeout
      end
      user_agent = "#{upstream.user_agent} " unless upstream.user_agent.to_s.empty?
      user_agent = user_agent.to_s + DEFAULT_USER_AGENT

      new(client, user_agent: user_agent)
    end

    def initialize(client = nil, user_agent: nil)
      @client = client
      @user_agent = user_agent || DEFAULT_USER_AGENT
    end

    def get(path)
      response = with_retries do
        @client.get(path) do |req|
          req.headers["User-Agent"] = @user_agent
          req.options.open_timeout = 2
        end
      end

      raise Gemstash::WebError.new(response.body, response.status) unless response.success?

      if block_given?
        yield(response.body, response.headers)
      else
        response.body
      end
    end

  private

    def with_retries(times: 3)
      loop do
        times -= 1
        begin
          return yield
        rescue Faraday::ConnectionFailed => e
          log_error("Connection failure", e)
          raise(ConnectionError, e.message) unless times > 0
          log.info "retrying... #{times} more times"
        end
      end
    end
  end
end
