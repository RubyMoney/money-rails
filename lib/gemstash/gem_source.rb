require "gemstash"
require "forwardable"

module Gemstash
  #:nodoc:
  module GemSource
    autoload :DependencyCaching, "gemstash/gem_source/dependency_caching"
    autoload :PrivateSource,     "gemstash/gem_source/private_source"
    autoload :RackMiddleware,    "gemstash/gem_source/rack_middleware"
    autoload :RedirectSource,    "gemstash/gem_source/upstream_source"
    autoload :RubygemsSource,    "gemstash/gem_source/upstream_source"
    autoload :UpstreamSource,    "gemstash/gem_source/upstream_source"

    def self.sources
      @sources ||= [
        Gemstash::GemSource::PrivateSource,
        Gemstash::GemSource::RedirectSource,
        Gemstash::GemSource::UpstreamSource,
        Gemstash::GemSource::RubygemsSource
      ]
    end

    # Base GemSource for some common utilities.
    class Base
      extend Forwardable
      extend Gemstash::Logging
      include Gemstash::Logging

      # Chomps the matching prefix against path variables in the Rack env. If it
      # matches all path variables, the prefix is stripped and the match results
      # from env["PATH_INFO"] are returned, otherwise a falsey value is
      # returned.
      def self.chomp_path(env, matcher)
        matcher = /\A#{Regexp.quote(matcher)}/ if matcher.is_a?(String)
        request_uri_match = env["REQUEST_URI"].match(matcher)
        return unless request_uri_match
        path_info_match = env["PATH_INFO"].match(matcher)
        return unless path_info_match
        log_start = "Rewriting '#{env["REQUEST_URI"]}'"
        env["REQUEST_URI"][request_uri_match.begin(0)...request_uri_match.end(0)] = ""
        env["PATH_INFO"][path_info_match.begin(0)...path_info_match.end(0)] = ""
        log.info "#{log_start} to '#{env["REQUEST_URI"]}'"
        path_info_match
      end

      def_delegators :@app, :cache_control, :content_type, :env, :halt, :headers, :params, :redirect, :request

      def initialize(app)
        @app = app
      end
    end
  end
end
