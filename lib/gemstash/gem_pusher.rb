require "rubygems/package"
require "stringio"

module Gemstash
  #:nodoc:
  class GemPusher
    #:nodoc:
    class ExistingVersionError < StandardError
    end

    #:nodoc:
    class YankedVersionError < ExistingVersionError
    end

    def initialize(content, db_helper = nil)
      @content = content
      @db_helper = db_helper || Gemstash::DBHelper.new
    end

    def push
      save_to_database
    end

  private

    def gem
      @gem ||= ::Gem::Package.new(StringIO.new(@content))
    end

    def save_to_database
      spec = gem.spec

      Gemstash::Env.db.transaction do
        gem_id = @db_helper.find_or_insert_rubygem(spec)
        existing = @db_helper.find_version(gem_id, spec)

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
  end
end
