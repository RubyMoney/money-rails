require "gemstash"
require "cgi"

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
        capture_user_agent(env)
        true
      end

      def self.capture_user_agent(env)
        env["gemstash.user-agent"] = env["HTTP_USER_AGENT"]
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
        redirect upstream.url("api/v1/dependencies", request.query_string)
      end

      def serve_dependencies_json
        redirect upstream.url("api/v1/dependencies.json", request.query_string)
      end

      def serve_names
        redirect upstream.url("names", request.query_string)
      end

      def serve_versions
        redirect upstream.url("versions", request.query_string)
      end

      def serve_info(name)
        redirect upstream.url("info/#{name}", request.query_string)
      end

      def serve_marshal(id)
        redirect upstream.url("quick/Marshal.4.8/#{id}", request.query_string)
      end

      def serve_actual_gem(id)
        redirect upstream.url("fetch/actual/gem/#{id}", request.query_string)
      end

      def serve_gem(id)
        redirect upstream.url("gems/#{id}", request.query_string)
      end

      def serve_latest_specs
        redirect upstream.url("latest_specs.4.8.gz", request.query_string)
      end

      def serve_specs
        redirect upstream.url("specs.4.8.gz", request.query_string)
      end

      def serve_prerelease_specs
        redirect upstream.url("prerelease_specs.4.8.gz", request.query_string)
      end

    private

      def upstream
        @upstream ||= Gemstash::Upstream.new(env["gemstash.upstream"],
          user_agent: env["gemstash.user-agent"])
      end
    end

    # GemSource for gems in an upstream server.
    class UpstreamSource < Gemstash::GemSource::RedirectSource
      include Gemstash::GemSource::DependencyCaching
      include Gemstash::Env::Helper

      def self.rack_env_rewriter
        @rack_env_rewriter ||= Gemstash::RackEnvRewriter.new(%r{\A/upstream/(?<upstream_url>[^/]+)})
      end

      def serve_marshal(id)
        serve_cached(id, :spec)
      end

      def serve_gem(id)
        serve_cached(id, :gem)
      end

    private

      def serve_cached(id, resource_type)
        gem = fetch_gem(id, resource_type)
        set_gem_headers(gem, resource_type)
        gem.content(resource_type)
      rescue Gemstash::WebError => e
        halt e.code
      end

      def set_gem_headers(gem, resource_type)
        return unless gem.property?(:headers, resource_type)
        gem_headers = gem.properties[:headers][resource_type]
        headers["Content-Type"] = gem_headers["content-type"] if gem_headers.include?("content-type")
        headers["Last-Modified"] = gem_headers["last-modified"] if gem_headers.include?("last-modified")
        headers["ETag"] = gem_headers["etag"] if gem_headers.include?("etag")
      end

      def dependencies
        @dependencies ||= begin
          http_client = http_client_for(upstream)
          Gemstash::Dependencies.for_upstream(upstream, http_client)
        end
      end

      def storage
        @storage ||= Gemstash::Storage.for("gem_cache")
        @storage.for(upstream.host_id)
      end

      def gem_fetcher
        @gem_fetcher ||= Gemstash::GemFetcher.new(http_client_for(upstream))
      end

      def fetch_gem(id, resource_type)
        gem_name = Gemstash::Upstream::GemName.new(upstream, id)
        gem_resource = storage.resource(gem_name.name)
        if gem_resource.exist?(resource_type)
          fetch_local_gem(gem_name, gem_resource, resource_type)
        else
          fetch_remote_gem(gem_name, gem_resource, resource_type)
        end
      end

      def fetch_local_gem(gem_name, gem_resource, resource_type)
        log.info "Gem #{gem_name.name} exists, returning cached #{resource_type}"
        gem_resource
      end

      def fetch_remote_gem(gem_name, gem_resource, resource_type)
        log.info "Gem #{gem_name.name} is not cached, fetching #{resource_type}"
        gem_fetcher.fetch(gem_name.id, resource_type) do |content, properties|
          resource_properties = {
            upstream: upstream.to_s,
            gem_name: gem_name.name,
            headers: { resource_type => properties }
          }

          gem = gem_resource.save({ resource_type => content }, resource_properties)
          Gemstash::DB::CachedRubygem.store(upstream, gem_name, resource_type)
          gem
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
        capture_user_agent(env)

        true
      end
    end
  end
end
