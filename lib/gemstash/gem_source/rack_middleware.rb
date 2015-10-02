module Gemstash
  module GemSource
    # Rack middleware to detect the gem source from the URL.
    class RackMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        Gemstash::GemSource.sources.each do |source|
          next unless source.matches?(env)
          env["gemstash.gem_source"] = source
          break
        end

        @app.call(env)
      end
    end
  end
end
