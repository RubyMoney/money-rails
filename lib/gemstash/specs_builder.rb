require "gemstash"
require "stringio"
require "zlib"

module Gemstash
  # Builds a Marshal'ed and GZipped array of arrays containing specs as:
  # [name, Gem::Version, platform]
  class SpecsBuilder
    attr_reader :result

    # Used for the /private/specs.4.8.gz endpoint. Fetches non-prerelease,
    # indexed private gems.
    def self.all
      new.build
    end

    def self.invalidate_stored
      storage = Gemstash::Storage.for("private").for("specs_collection")
      storage.resource("specs.4.8.gz").delete
    end

    def build
      fetch_from_storage
      return result if result
      fetch_versions
      marshal
      gzip
      store_result
      result
    end

  private

    def storage
      @storage ||= Gemstash::Storage.for("private").for("specs_collection")
    end

    def fetch_from_storage
      specs = storage.resource("specs.4.8.gz")
      return unless specs.exist?
      @result = specs.load.content
    rescue
      # On the off-chance of a race condition between specs.exist? and specs.load
      @result = nil
    end

    def fetch_versions
      @versions = Gemstash::DB::Version.indexed_and_released.map(&:to_spec)
    end

    def marshal
      @marshal ||= Marshal.dump(@versions)
    end

    def gzip
      @result ||= begin
        output = StringIO.new
        gz = Zlib::GzipWriter.new(output)

        begin
          gz.write(@marshal)
        ensure
          gz.close
        end

        output.string
      end
    end

    def store_result
      storage.resource("specs.4.8.gz").save(@result)
    end
  end
end
