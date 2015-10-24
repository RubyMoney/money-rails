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
      @db_helper = Gemstash::DBHelper.new
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
      raise Gemstash::NotAuthorizedError, "Authorization key required" if @auth_key.to_s.strip.empty?
      auth = Authorization[@auth_key]
      raise Gemstash::NotAuthorizedError, "Authorization key is invalid" unless auth
      raise Gemstash::NotAuthorizedError, "Authorization key doesn't have push access" unless auth.push?
    end

    def store_gem
      storage.resource(gem.spec.full_name).save(@content)
    end

    def save_to_database
      spec = gem.spec

      gemstash_env.db.transaction do
        gem_id = @db_helper.find_or_insert_rubygem(spec)
        existing = @db_helper.find_version(gem_id, spec: spec)

        if existing
          if existing[:indexed]
            raise ExistingVersionError, "Cannot push to an existing version!"
          else
            raise YankedVersionError, "Cannot push to a yanked version!"
          end
        end

        version_id = @db_helper.insert_version(gem_id, spec)
        @db_helper.insert_dependencies(version_id, spec)
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
