require "gemstash"
require "cgi"

module Gemstash
  module GemSource
    # GemSource for gems in an upstream server.
    class UpstreamSource < Gemstash::GemSource::Base
      def self.matches?(env)
        match = chomp_path(env, %r{\A/upstream/([^/]+)})
        return false unless match
        env["gemstash.upstream"] = CGI.unescape(match[1])
        true
      end

      def serve_root
        cache_control :public, :max_age => 31_536_000
        redirect web_helper.url
      end

      def serve_marshal(id)
        redirect web_helper.url("/quick/Marshal.4.8/#{id}")
      end

      def serve_actual_gem(id)
        redirect web_helper.url("/fetch/actual/gem/#{id}")
      end

      def serve_gem(id)
        gem = fetch_gem(id)
        headers.update(gem.headers)
        gem.content
      rescue Gemstash::WebError => e
        halt e.code
      end

      def serve_latest_specs
        redirect web_helper.url("/latest_specs.4.8.gz")
      end

      def serve_specs
        redirect web_helper.url("/specs.4.8.gz")
      end

      def serve_prerelease_specs
        redirect web_helper.url("/prerelease_specs.4.8.gz")
      end

    private

      def web_helper
        @web_helper ||= Gemstash::WebHelper.new(server_url: env["gemstash.upstream"])
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
