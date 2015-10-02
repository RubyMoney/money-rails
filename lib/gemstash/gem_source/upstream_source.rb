require "gemstash"
require "cgi"

module Gemstash
  module GemSource
    # GemSource that purely redirects to the upstream server.
    class RedirectSource < Gemstash::GemSource::Base
      def self.matches?(env)
        match = chomp_path(env, %r{\A/redirect/([^/]+)})
        return false unless match
        env["gemstash.upstream"] = CGI.unescape(match[1])
        true
      end

      def serve_root
        cache_control :public, :max_age => 31_536_000
        redirect web_helper.url(nil, request.query_string)
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
        redirect web_helper.url("/api/v1/dependencies", request.query_string)
      end

      def serve_dependencies_json
        redirect web_helper.url("/api/v1/dependencies.json", request.query_string)
      end

      def serve_names
        redirect web_helper.url("/names", request.query_string)
      end

      def serve_versions
        redirect web_helper.url("/versions", request.query_string)
      end

      def serve_info(name)
        redirect web_helper.url("/info/#{name}", request.query_string)
      end

      def serve_marshal(id)
        redirect web_helper.url("/quick/Marshal.4.8/#{id}", request.query_string)
      end

      def serve_actual_gem(id)
        redirect web_helper.url("/fetch/actual/gem/#{id}", request.query_string)
      end

      def serve_gem(id)
        redirect web_helper.url("/gems/#{id}", request.query_string)
      end

      def serve_latest_specs
        redirect web_helper.url("/latest_specs.4.8.gz", request.query_string)
      end

      def serve_specs
        redirect web_helper.url("/specs.4.8.gz", request.query_string)
      end

      def serve_prerelease_specs
        redirect web_helper.url("/prerelease_specs.4.8.gz", request.query_string)
      end

    private

      def web_helper
        @web_helper ||= Gemstash::WebHelper.new(server_url: env["gemstash.upstream"])
      end
    end

    # GemSource for gems in an upstream server.
    class UpstreamSource < Gemstash::GemSource::RedirectSource
      include Gemstash::GemSource::DependencyCaching

      def self.matches?(env)
        match = chomp_path(env, %r{\A/upstream/([^/]+)})
        return false unless match
        env["gemstash.upstream"] = CGI.unescape(match[1])
        true
      end

      def serve_gem(id)
        gem = fetch_gem(id)
        headers.update(gem.headers)
        gem.content
      rescue Gemstash::WebError => e
        halt e.code
      end

    private

      def dependencies
        @dependencies ||= Gemstash::Dependencies.for_upstream(web_helper)
      end

      def storage
        @storage ||= Gemstash::GemStorage.new
      end

      def fetch_gem(id)
        gem = storage.get(id)
        if gem.exist?
          log.info "Gem #{id} exists, returning cached"
          gem
        else
          log.info "Gem #{id} is not cached, fetching"
          web_helper.get("/gems/#{id}") do |body, headers|
            gem.save(headers, body)
          end
        end
      end
    end

    # GemSource for https://rubygems.org (specifically when defined by using the
    # default upstream).
    class RubygemsSource < Gemstash::GemSource::UpstreamSource
      def self.matches?(env)
        env["gemstash.upstream"] = env["gemstash.env"].config[:rubygems_url]
        true
      end
    end
  end
end
