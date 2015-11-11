require "gemstash"
require "digest"
require "pathname"
require "fileutils"
require "yaml"

module Gemstash
  #:nodoc:
  class Storage
    extend Gemstash::Env::Helper
    VERSION = 1

    # If the storage engine detects something that was stored with a newer
    # version of the storage engine, this error will be thrown.
    class VersionTooNew < StandardError
    end

    def initialize(folder, root: true)
      check_engine if root
      @folder = folder
      FileUtils.mkpath(@folder) unless Dir.exist?(@folder)
    end

    def resource(id)
      Resource.new(@folder, id)
    end

    def for(child)
      Storage.new(File.join(@folder, child), root: false)
    end

    def self.for(name)
      new(gemstash_env.base_file(name))
    end

    def self.metadata
      file = gemstash_env.base_file("metadata.yml")

      unless File.exist?(file)
        File.write(file, { storage_version: Gemstash::Storage::VERSION,
                           gemstash_version: Gemstash::VERSION }.to_yaml)
      end

      YAML.load_file(file)
    end

  private

    def check_engine
      version = Gemstash::Storage.metadata[:storage_version]
      return if version <= Gemstash::Storage::VERSION
      raise Gemstash::Storage::VersionTooNew, "Storage engine is out of date: #{version}"
    end

    def path_valid?(path)
      return false if path.nil?
      return false unless File.writable?(path)
      true
    end
  end

  #:nodoc:
  class Resource
    include Gemstash::Logging
    attr_reader :name, :folder
    def initialize(folder, name)
      @base_path = folder
      @name = name
      # Avoid odd characters in paths, in case of issues with the file system
      safe_name = @name.gsub(/[^a-zA-Z0-9_]/, "_")
      # Use a trie structure to avoid file system limits causing too many files in 1 folder
      # Downcase to avoid issues with case insensitive file systems
      trie_parents = safe_name[0...3].downcase.split("")
      # The digest is included in case the name differs only by case
      # Some file systems are case insensitive, so such collisions will be a problem
      digest = Digest::MD5.hexdigest(@name)
      child_folder = "#{safe_name}-#{digest}"
      @folder = File.join(@base_path, *trie_parents, child_folder)
    end

    def exist?
      File.exist?(content_filename) && File.exist?(properties_filename)
    end

    def save(content, properties = nil)
      save_content(content)
      save_properties(properties)
      self
    end

    def content
      @content
    end

    def properties
      @properties || {}
    end

    def update_properties(props)
      load
      save_properties(properties.merge(props))
      self
    end

    def load
      raise "Resource #{@name} has no content to load" unless exist?
      @properties = YAML.load_file(properties_filename)
      version = @properties[:gemstash_storage_version]

      if version > Gemstash::Storage::VERSION
        @properties = nil
        raise Gemstash::Storage::VersionTooNew, "Resource was stored with a newer storage: #{version}"
      end

      @content = read_file(content_filename)
      self
    end

    def delete
      return unless exist?

      begin
        File.delete(content_filename)
      rescue => e
        log_error "Failed to delete stored content at #{content_filename}", e, level: :warn
      end

      begin
        File.delete(properties_filename)
      rescue => e
        log_error "Failed to delete stored properties at #{properties_filename}", e, level: :warn
      end
    ensure
      @content = nil
      @properties = nil
    end

  private

    def save_content(content)
      store(content_filename, content)
      @content = content
    end

    def save_properties(props)
      props ||= {}
      props = { gemstash_storage_version: Gemstash::Storage::VERSION }.merge(props)
      store(properties_filename, props.to_yaml)
      @properties = props
    end

    def store(filename, content)
      FileUtils.mkpath(@folder) unless Dir.exist?(@folder)
      save_file(filename) { content }
    end

    def save_file(filename)
      content = yield
      File.open(filename, "wb") {|f| f.write(content) }
    end

    def read_file(filename)
      File.open(filename, "rb", &:read)
    end

    def content_filename
      File.join(@folder, "content")
    end

    def properties_filename
      File.join(@folder, "properties.yaml")
    end
  end
end
