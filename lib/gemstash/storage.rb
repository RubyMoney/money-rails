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
      def initialize(msg, folder, version)
        super("#{msg} (location: #{folder}, version: #{version}, expected version: <= #{Gemstash::Storage::VERSION})")
      end
    end

    def initialize(folder, root: true)
      @folder = folder
      check_engine if root
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
      raise Gemstash::Storage::VersionTooNew.new("Storage engine is out of date", @folder, version)
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
      safe_name = sanitize(@name)
      # Use a trie structure to avoid file system limits causing too many files in 1 folder
      # Downcase to avoid issues with case insensitive file systems
      trie_parents = safe_name[0...3].downcase.split("")
      # The digest is included in case the name differs only by case
      # Some file systems are case insensitive, so such collisions will be a problem
      digest = Digest::MD5.hexdigest(@name)
      child_folder = "#{safe_name}-#{digest}"
      @folder = File.join(@base_path, *trie_parents, child_folder)
    end

    def exist?(key = nil)
      if key
        File.exist?(properties_filename) && File.exist?(content_filename(key))
      else
        File.exist?(properties_filename) && content?
      end
    end

    def save(content, properties = nil)
      content.each do |key, value|
        save_content(key, value)
      end

      update_properties(properties)
      self
    end

    def content(key)
      @content[key]
    end

    def properties
      @properties || {}
    end

    def update_properties(props)
      load_properties
      save_properties(properties.merge(props || {}))
      self
    end

    def load(key)
      raise "Resource #{@name} has no content to load" unless exist?(key)
      load_properties
      @content ||= {}
      @content[key] = read_file(content_filename(key))
      self
    end

    def delete(key)
      return self unless exist?(key)

      begin
        File.delete(content_filename(key))
      rescue => e
        log_error "Failed to delete stored content at #{content_filename(key)}", e, level: :warn
      end

      begin
        File.delete(properties_filename) unless content?
      rescue => e
        log_error "Failed to delete stored properties at #{properties_filename}", e, level: :warn
      end

      return self
    ensure
      reset
    end

  private

    def load_properties
      return unless File.exist?(properties_filename)
      @properties = YAML.load_file(properties_filename)
      check_version
    end

    def check_version
      version = @properties[:gemstash_storage_version]
      return if version <= Gemstash::Storage::VERSION
      reset
      raise Gemstash::Storage::VersionTooNew.new("Resource was stored with a newer storage", @folder, version)
    end

    def reset
      @content = nil
      @properties = nil
    end

    def content?
      return false unless Dir.exist?(@folder)
      entries = Dir.entries(@folder).reject {|file| file =~ /\A\.\.?\z/ }
      !entries.empty? && entries != %w(properties.yaml)
    end

    def sanitize(name)
      name.gsub(/[^a-zA-Z0-9_]/, "_")
    end

    def save_content(key, content)
      store(content_filename(key), content)
      @content ||= {}
      @content[key] = content
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

    def content_filename(key)
      name = sanitize(key.to_s)
      raise "Invalid content key #{key.inspect}" if name.empty?
      File.join(@folder, name)
    end

    def properties_filename
      File.join(@folder, "properties.yaml")
    end
  end
end
