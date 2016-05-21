require "gemstash"

module Gemstash
  # Authorize actions via an API key and Gemstash::Authorization.
  class ApiKeyAuthorization
    def initialize(key)
      @key = key
    end

    def self.protect(app, &block)
      key = parse_authorization(app.request.env)
      app.auth = new(key)
      yield
    rescue Gemstash::NotAuthorizedError => e
      app.headers["WWW-Authenticate"] = "Basic realm=\"Gemstash Private Gems\""
      app.halt 401, e.message
    end

    def self.parse_authorization(request_env)
      http_auth = Rack::Auth::Basic::Request.new(request_env)
      return http_auth.credentials.first if http_auth.provided? && http_auth.basic?
      request_env["HTTP_AUTHORIZATION"]
    end

    def check(permission)
      Gemstash::Authorization.check(@key, permission)
    end
  end
end
