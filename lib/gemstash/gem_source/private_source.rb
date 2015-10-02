require "gemstash"

module Gemstash
  module GemSource
    # GemSource for privately stored gems.
    class PrivateSource < Gemstash::GemSource::Base
      def self.matches?(env)
        chomp_path(env, "/private")
      end

      def serve_root
        halt 403, "Not yet supported"
      end

      def serve_add_gem
        authenticated("Gemstash Private Gems") do
          halt 403, "Not yet supported"
          auth = request.env["HTTP_AUTHORIZATION"]
          gem = request.body.read
          Gemstash::GemPusher.new(auth, gem).push
        end
      end

      def serve_yank
        halt 403, "Not yet supported"
      end

      def serve_unyank
        halt 403, "Not yet supported"
      end

      def serve_add_spec_json
        halt 403, "Not yet supported"
      end

      def serve_remove_spec_json
        halt 403, "Not yet supported"
      end

      def serve_names
        halt 403, "Not yet supported"
      end

      def serve_versions
        halt 403, "Not yet supported"
      end

      def serve_info(name)
        halt 403, "Not yet supported"
      end

      def serve_marshal(id)
        halt 403, "Not yet supported"
      end

      def serve_actual_gem(id)
        halt 403, "Not yet supported"
      end

      def serve_gem(id)
        halt 403, "Not yet supported"
      end

      def serve_latest_specs
        halt 403, "Not yet supported"
      end

      def serve_specs
        halt 403, "Not yet supported"
      end

      def serve_prerelease_specs
        halt 403, "Not yet supported"
      end

    private

      def authenticated(realm)
        yield
      rescue Gemstash::NotAuthorizedError => e
        headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\""
        halt 401, e.message
      end
    end
  end
end
