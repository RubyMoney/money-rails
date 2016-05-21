require "gemstash"

module Gemstash
  module GemSource
    # GemSource for privately stored gems.
    class PrivateSource < Gemstash::GemSource::Base
      include Gemstash::GemSource::DependencyCaching
      include Gemstash::Env::Helper
      attr_accessor :auth

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
        authenticated(Gemstash::GemPusher)
      end

      def serve_yank
        authenticated(Gemstash::GemYanker)
      end

      def serve_unyank
        authenticated(Gemstash::GemUnyanker)
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
        gem_full_name = id.sub(/\.gemspec\.rz\z/, "")
        gem = fetch_gem(gem_full_name)
        halt 404 unless gem.exist?(:spec)
        content_type "application/octet-stream"
        gem.content(:spec)
      end

      def serve_actual_gem(id)
        halt 403, "Not yet supported"
      end

      def serve_gem(id)
        gem_full_name = id.sub(/\.gem\z/, "")
        gem = fetch_gem(gem_full_name)
        content_type "application/octet-stream"
        gem.content(:gem)
      end

      def serve_latest_specs
        halt 403, "Not yet supported"
      end

      def serve_specs
        content_type "application/octet-stream"
        Gemstash::SpecsBuilder.all
      end

      def serve_prerelease_specs
        content_type "application/octet-stream"
        Gemstash::SpecsBuilder.prerelease
      end

    private

      def authenticated(servable)
        authorization.serve(self, servable)
      end

      def authorization
        Gemstash::ApiKeyAuthorization
      end

      def dependencies
        @dependencies ||= Gemstash::Dependencies.for_private
      end

      def storage
        @storage ||= Gemstash::Storage.for("private").for("gems")
      end

      def fetch_gem(gem_full_name)
        gem = storage.resource(gem_full_name)
        halt 404 unless gem.exist?(:gem)
        halt 403, "That gem has been yanked" unless gem.properties[:indexed]
        gem
      end
    end
  end
end
