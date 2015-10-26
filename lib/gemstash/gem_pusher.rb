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

    def initialize(auth_key, content)
      @auth_key = auth_key
      @content = content
    end

    def push
      check_auth
      store_gem
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

    def check_auth
      Gemstash::Authorization.check(@auth_key, "push")
    end

    def store_gem
      storage.resource(gem.spec.full_name).save(@content)
    end

    def save_to_database
      spec = gem.spec

      gemstash_env.db.transaction do
        gem_id = Gemstash::DB::Rubygem.find_or_insert(spec)
        existing = Gemstash::DB::Version.find_by_spec(gem_id, spec)

        if existing
          if existing.indexed
            raise ExistingVersionError, "Cannot push to an existing version!"
          else
            raise YankedVersionError, "Cannot push to a yanked version!"
          end
        end

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
          alias_method :push_without_cleanup, :push
          remove_method :push
          remove_method :gem
        end
      end

      def push
        push_without_cleanup
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
