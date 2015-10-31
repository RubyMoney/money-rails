require "gemstash"

module Gemstash
  module GemSource
    # GemSource for privately stored gems.
    class PrivateSource < Gemstash::GemSource::Base
      include Gemstash::GemSource::DependencyCaching
      include Gemstash::Env::Helper

      def self.rack_env_rewriter
        @rack_env_rewriter ||= Gemstash::RackEnvRewriter.new(%r{\A/private})
      end

      def self.matches?(env)
        rewriter = rack_env_rewriter.for(env)
        return false unless rewriter.matches?
        rewriter.rewrite
        true
      end

      def serve_root
        halt 403, "Not yet supported"
      end

      def serve_add_gem
        authenticated("Gemstash Private Gems") do
          auth = request.env["HTTP_AUTHORIZATION"]
          gem = request.body.read
          Gemstash::GemPusher.new(auth, gem).push
        end
      end

      def serve_yank
        authenticated("Gemstash Private Gems") do
          auth = request.env["HTTP_AUTHORIZATION"]
          gem_name = params[:gem_name]
          Gemstash::GemYanker.new(auth, gem_name, slug_param).yank
        end
      end

      def serve_unyank
        authenticated("Gemstash Private Gems") do
          auth = request.env["HTTP_AUTHORIZATION"]
          gem_name = params[:gem_name]
          Gemstash::GemUnyanker.new(auth, gem_name, slug_param).unyank
        end
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
        gem_full_name = id.sub(/\.gem\z/, "")
        gem = storage.resource(gem_full_name)
        halt 404 unless gem.exist?
        gem.load
        halt 403, "That gem has been yanked" unless gem.properties[:indexed]
        content_type "application/octet-stream"
        gem.content
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

      def slug_param
        version = params[:version]
        platform = params[:platform]

        if platform.to_s.empty?
          version
        else
          "#{version}-#{platform}"
        end
      end

      def authenticated(realm)
        yield
      rescue Gemstash::NotAuthorizedError => e
        headers["WWW-Authenticate"] = "Basic realm=\"#{realm}\""
        halt 401, e.message
      end

      def dependencies
        @dependencies ||= Gemstash::Dependencies.for_private
      end

      def storage
        @storage ||= Gemstash::Storage.for("private").for("gems")
      end
    end
  end
end
