# frozen_string_literal: true

require "gemstash"
require "rubygems/package"
require "stringio"

#:nodoc:
module Gemstash
  # Class that supports pushing a new gem to the private repository of gems.
  class GemPusher
    include Gemstash::Env::Helper

    # This error is thrown when pushing to an existing version.
    class ExistingVersionError < StandardError
    end

    # This error is thrown when pushing to a yanked version.
    class YankedVersionError < ExistingVersionError
    end

    def self.serve(app)
      gem = app.request.body.read
      new(app.auth, gem).serve
    end

    def initialize(auth, content)
      @auth = auth
      @content = content
    end

    def serve
      check_auth
      store_gem
      store_gemspec
      save_to_database
      invalidate_cache
    end

  private

    def gem
      @gem ||= Gem::Package.new(StringIO.new(@content))
    end

    def storage
      @storage ||= Gemstash::Storage.for("private").for("gems")
    end

    def full_name
      @full_name ||= gem.spec.full_name
    end

    def check_auth
      @auth.check("push")
    end

    def store_gem
      resource_exist = storage.resource(full_name).exist?
      resource_is_indexed = storage.resource(full_name).properties[:indexed] if resource_exist

      raise ExistingVersionError, "Cannot push to an existing version!" if resource_exist && resource_is_indexed

      storage.resource(full_name).save({ gem: @content }, indexed: true)
    end

    def store_gemspec
      spec = gem.spec
      spec = Marshal.dump(spec)
      spec = Zlib::Deflate.deflate(spec)
      storage.resource(full_name).save(spec: spec)
    end

    def save_to_database
      spec = gem.spec

      gemstash_env.db.transaction do
        gem_id = Gemstash::DB::Rubygem.find_or_insert(spec)
        existing = Gemstash::DB::Version.find_by_spec(gem_id, spec)
        raise ExistingVersionError, "Cannot push to an existing version!" if existing && existing.indexed
        raise YankedVersionError, "Cannot push to a yanked version!" if existing && !existing.indexed

        version_id = Gemstash::DB::Version.insert_by_spec(gem_id, spec)
        Gemstash::DB::Dependency.insert_by_spec(version_id, spec)
      end
    end

    def invalidate_cache
      gemstash_env.cache.invalidate_gem("private", gem.spec.name)
    end
  end

  unless Gem::Requirement.new(">= 2.4").satisfied_by?(Gem::Version.new(Gem::VERSION))
    require "tempfile"

    # Adds support for legacy versions of RubyGems
    module LegacyRubyGemsSupport
      def self.included(base)
        base.class_eval do
          alias_method :serve_without_cleanup, :serve
          remove_method :serve
          remove_method :gem
        end
      end

      def serve
        serve_without_cleanup
      ensure
        cleanup
      end

    private

      def gem
        @gem ||= begin
          @tempfile = Tempfile.new("gemstash-gem")
          @tempfile.write(@content)
          @tempfile.flush
          Gem::Package.new(@tempfile.path)
        end
      end

      def cleanup
        return unless @tempfile

        @tempfile.close
        @tempfile.unlink
      end
    end

    GemPusher.send(:include, LegacyRubyGemsSupport)
  end
end
