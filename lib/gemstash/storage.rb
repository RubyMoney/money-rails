require "pathname"
require "fileutils"
require "yaml"

module Gemstash
  #:nodoc:
  class Storage
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

  private

    def path_valid?(path)
      return false if path.nil?
      return false unless File.writable?(path)
      true
    end
  end

  #:nodoc:
  class Resource
    def initialize(folder, name)
      @base_path = folder
      @name = name
      @folder = File.join(@base_path, @name)
    end

    def exist?
      File.exist?(content_filename) && File.exist?(properties_filename)
    end

    def save(content, properties: nil)
      @content = content
      @properties = properties
      store
    end

    def content
      @content
    end

    def properties
      @properties
    end

    def load
      raise "Resource #{@name} has no content to load" unless exist?
      @content = read_file(content_filename)
      @properties = read_file(properties_filename)
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
      File.open(filename, "w") {|f| f.write(content) }
    end

    def read_file(filename)
      File.open(filename, &:read)
    end

    def content_filename
      File.join(@folder, "content")
    end

    def properties_filename
      File.join(@folder, "properties.yaml")
    end
  end
end
