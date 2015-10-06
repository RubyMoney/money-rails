require "gemstash"
require "cgi"
require "set"

module Gemstash
  module GemSource
    # GemSource that purely redirects to the upstream server.
    class RedirectSource < Gemstash::GemSource::Base
      def self.rack_env_rewriter
        @rack_env_rewriter ||= Gemstash::RackEnvRewriter.new(%r{\A/redirect/(?<upstream_url>[^/]+)})
      end

      def self.matches?(env)
        rewriter = rack_env_rewriter.for(env)
        return false unless rewriter.matches?
        rewriter.rewrite
        env["gemstash.upstream"] = rewriter.captures["upstream_url"]
        true
      end

      def serve_root
        cache_control :public, :max_age => 31_536_000
        redirect upstream.url(nil, request.query_string)
      end

      def serve_add_gem
        halt 403, "Cannot add gem to an upstream server!"
      end

      def serve_yank
        halt 403, "Cannot yank from an upstream server!"
      end

      def serve_unyank
        halt 403, "Cannot unyank from an upstream server!"
      end

      def serve_add_spec_json
        halt 403, "Cannot add spec to an upstream server!"
      end

      def serve_remove_spec_json
        halt 403, "Cannot remove spec from an upstream server!"
      end

      def serve_dependencies
        redirect upstream.url("/api/v1/dependencies", request.query_string)
      end

      def serve_dependencies_json
        redirect upstream.url("/api/v1/dependencies.json", request.query_string)
      end

      def serve_names
        redirect upstream.url("/names", request.query_string)
      end

      def serve_versions
        redirect upstream.url("/versions", request.query_string)
      end

      def serve_info(name)
        redirect upstream.url("/info/#{name}", request.query_string)
      end

      def serve_marshal(id)
        redirect upstream.url("/quick/Marshal.4.8/#{id}", request.query_string)
      end

      def serve_actual_gem(id)
        redirect upstream.url("/fetch/actual/gem/#{id}", request.query_string)
      end

      def serve_gem(id)
        redirect upstream.url("/gems/#{id}", request.query_string)
      end

      def serve_latest_specs
        redirect upstream.url("/latest_specs.4.8.gz", request.query_string)
      end

      def serve_specs
        redirect upstream.url("/specs.4.8.gz", request.query_string)
      end

      def serve_prerelease_specs
        redirect upstream.url("/prerelease_specs.4.8.gz", request.query_string)
      end

    private

      def web_helper
        @web_helper ||= Gemstash::WebHelper.new(
          http_client: http_client_for(upstream.to_s),
          server_url: upstream.to_s)
      end

      def upstream
        @upstream ||= Gemstash::Upstream.new(env["gemstash.upstream"])
      end
    end

    # GemSource for gems in an upstream server.
    class UpstreamSource < Gemstash::GemSource::RedirectSource
      include Gemstash::GemSource::DependencyCaching
      include Gemstash::Env::Helper

      def self.rack_env_rewriter
        @rack_env_rewriter ||= Gemstash::RackEnvRewriter.new(%r{\A/upstream/(?<upstream_url>[^/]+)})
      end

      def serve_gem(id)
        gem = fetch_gem(id)
        headers.update(gem.properties)
        gem.content
      rescue Gemstash::WebError => e
        halt e.code
      end

    private

      def dependencies
        @dependencies ||= Gemstash::Dependencies.for_upstream(web_helper)
      end

      def storage
        @storage ||= Gemstash::Storage.new(gemstash_env.base_file("gem_cache"))
        @storage.for(upstream.host_id)
      end

      def fetch_gem(id)
        gem_name = Gemstash::UpstreamGemName.new(upstream, id)
        gem_resource = storage.resource(gem_name.name)
        if gem_resource.exist?
          fetch_local_gem(gem_name, gem_resource)
        else
          fetch_remote_gem(gem_name, gem_resource)
        end
      end

      def fetch_local_gem(gem_name, gem_resource)
        log.info "Gem #{gem_name.name} exists, returning cached"
        gem_resource.load
      end

      def fetch_remote_gem(gem_name, gem_resource)
        log.info "Gem #{gem_name.name} is not cached, fetching"
        valid_headers = Set.new(["etag", "content-type", "content-length", "last-modified"])
        web_helper.get("/gems/#{gem_name.id}") do |body, headers|
          properties = headers.select {|key, _value| valid_headers.include?(key.downcase) }
          gem_resource.save(body, properties: properties)
        end
      end
    end

    # GemSource for https://rubygems.org (specifically when defined by using the
    # default upstream).
    class RubygemsSource < Gemstash::GemSource::UpstreamSource
      def self.matches?(env)
        if env["HTTP_X_GEMFILE_SOURCE"].to_s.empty?
          env["gemstash.upstream"] = env["gemstash.env"].config[:rubygems_url]
        else
          env["gemstash.upstream"] = env["HTTP_X_GEMFILE_SOURCE"]
        end

        true
      end
    end
  end
end
