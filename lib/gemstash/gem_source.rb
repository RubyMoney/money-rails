# frozen_string_literal: true

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

      def_delegators :@app, :cache_control, :content_type, :env, :halt,
        :headers, :http_client_for, :params, :redirect, :request

      def initialize(app)
        @app = app
      end
    end
  end
end
