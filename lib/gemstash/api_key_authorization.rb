require "gemstash"

module Gemstash
  # Authorize actions via an API key and Gemstash::Authorization.
  class ApiKeyAuthorization
    def initialize(key)
      @key = key
    end

    def self.serve(app, servable)
      key = app.request.env["HTTP_AUTHORIZATION"]
      app.auth = new(key)
      servable.serve(app)
    rescue Gemstash::NotAuthorizedError => e
      app.headers["WWW-Authenticate"] = "Basic realm=\"Gemstash Private Gems\""
      app.halt 401, e.message
    end

    def check(permission)
      Gemstash::Authorization.check(@key, permission)
    end
  end
end
