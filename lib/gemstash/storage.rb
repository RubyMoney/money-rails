require "gemstash"
require "digest"
require "pathname"
require "fileutils"
require "yaml"

module Gemstash
  #:nodoc:
  class Storage
    extend Gemstash::Env::Helper

    def initialize(folder)
      @folder = folder
      FileUtils.mkpath(@folder) unless Dir.exist?(@folder)
    end

    def resource(id)
      Resource.new(@folder, id)
    end

    def for(child)
      Storage.new(File.join(@folder, child))
    end

    def self.for(name)
      new(gemstash_env.base_file(name))
    end

  private

    def path_valid?(path)
      return false if path.nil?
      return false unless File.writable?(path)
      true
    end
  end

  #:nodoc:
  class Resource
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
      @content = content
      @properties = properties
      store
    end

    def content
      @content
    end

    def properties
      @properties || {}
    end

    def load
      raise "Resource #{@name} has no content to load" unless exist?
      @content = read_file(content_filename)
      @properties = YAML.load_file(properties_filename)
      self
    end

  private

    def store
      FileUtils.mkpath(@folder) unless Dir.exist?(@folder)
      save_file(content_filename) { @content }
      save_file(properties_filename) { @properties.to_yaml }
      self
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
