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
