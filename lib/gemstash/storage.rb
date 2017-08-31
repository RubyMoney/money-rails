require "gemstash"
require "digest"
require "fileutils"
require "pathname"
require "yaml"

module Gemstash
  # The entry point into the storage engine for storing cached gems, specs, and
  # private gems.
  class Storage
    extend Gemstash::Env::Helper
    VERSION = 1

    # If the storage engine detects the base cache directory was originally
    # initialized with a newer version, this error is thrown.
    class VersionTooNew < StandardError
      def initialize(folder, version)
        super("Gemstash storage version #{Gemstash::Storage::VERSION} does " \
              "not support version #{version} found at #{folder}")
      end
    end

    # This object should not be constructed directly, but instead via
    # {for} and {#for}.
    def initialize(folder, root: true)
      @folder = folder
      check_storage_version if root
      FileUtils.mkpath(@folder) unless Dir.exist?(@folder)
    end

    # Fetch the resource with the given +id+ within this storage.
    #
    # @param id [String] the id of the resource to fetch
    # @return [Gemstash::Resource] a new resource instance from the +id+
    def resource(id)
      Resource.new(@folder, id)
    end

    # Fetch a nested entry from this instance in the storage engine.
    #
    # @param child [String] the name of the nested entry to load
    # @return [Gemstash::Storage] a new storage instance for the +child+
    def for(child)
      Storage.new(File.join(@folder, child), root: false)
    end

    # Fetch a base entry in the storage engine.
    #
    # @param name [String] the name of the entry to load
    # @return [Gemstash::Storage] a new storage instance for the +name+
    def self.for(name)
      new(gemstash_env.base_file(name))
    end

    # Read the global metadata for Gemstash and the storage engine. If the
    # metadata hasn't been stored yet, it will be created.
    #
    # @return [Hash] the metadata about Gemstash and the storage engine
    def self.metadata
      file = gemstash_env.base_file("metadata.yml")

      unless File.exist?(file)
        gemstash_env.atomic_write(file) do |f|
          f.write({ storage_version: Gemstash::Storage::VERSION,
                    gemstash_version: Gemstash::VERSION }.to_yaml)
        end
      end

      YAML.load_file(file)
    end

  private

    def check_storage_version
      version = Gemstash::Storage.metadata[:storage_version]
      return if version <= Gemstash::Storage::VERSION
      raise Gemstash::Storage::VersionTooNew.new(@folder, version)
    end

    def path_valid?(path)
      return false if path.nil?
      return false unless File.writable?(path)
      true
    end
  end

  # A resource within the storage engine. The resource may have 1 or more files
  # associated with it along with a metadata Hash that is stored in a YAML file.
  class Resource
    include Gemstash::Env::Helper
    include Gemstash::Logging
    attr_reader :name, :folder
    VERSION = 1

    # If the storage engine detects a resource was originally saved from a newer
    # version, this error is thrown.
    class VersionTooNew < StandardError
      def initialize(name, folder, version)
        super("Gemstash resource version #{Gemstash::Resource::VERSION} does " \
              "not support version #{version} for resource #{name.inspect} " \
              "found at #{folder}")
      end
    end

    # This object should not be constructed directly, but instead via
    # {Gemstash::Storage#resource}.
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
      @properties = nil
    end

    # When +key+ is nil, this will test if this resource exists with any
    # content. If a +key+ is provided, this will test that the resource exists
    # with at least the given +key+ file. The +key+ corresponds to the +content+
    # key provided to {#save}.
    #
    # @param key [Symbol, nil] the key of the content to check existence
    # @return [Boolean] true if the indicated content exists
    def exist?(key = nil)
      if key
        File.exist?(properties_filename) && File.exist?(content_filename(key))
      else
        File.exist?(properties_filename) && content?
      end
    end

    # Save one or more files for this resource given by the +content+ hash.
    # Metadata properties about the file(s) may be provided in the optional
    # +properties+ parameter. The keys in the content hash correspond to the
    # file name for this resource, while the values will be the content stored
    # for that key.
    #
    # Separate calls to save for the same resource will replace existing files,
    # and add new ones. Properties on additional calls will be merged with
    # existing properties. Nested hashes in properties will also be merged.
    #
    # Examples:
    #
    #   Gemstash::Storage.for("foo").resource("bar").save(baz: "qux")
    #   Gemstash::Storage.for("foo").resource("bar").save(baz: "one", qux: "two")
    #   Gemstash::Storage.for("foo").resource("bar").save({ baz: "qux" }, meta: true)
    #
    # @param content [Hash{Symbol => String}] files to save, *must not be nil*
    # @param properties [Hash, nil] metadata properties related to this resource
    # @return [Gemstash::Resource] self for chaining purposes
    def save(content, properties = nil)
      content.each do |key, value|
        save_content(key, value)
      end

      update_properties(properties)
      self
    end

    # Fetch the content for the given +key+. This will load and cache the
    # properties and the content of the +key+. The +key+ corresponds to the
    # +content+ key provided to {#save}.
    #
    # @param key [Symbol] the key of the content to load
    # @return [String] the content stored in the +key+
    def content(key)
      @content ||= {}
      load(key) unless @content.include?(key)
      @content[key]
    end

    # Fetch the metadata properties for this resource. The properties will be
    # cached for future calls.
    #
    # @return [Hash] the metadata properties for this resource
    def properties
      load_properties
      @properties || {}
    end

    # Update the metadata properties of this resource. The +props+ will be
    # merged with any existing properties. Nested hashes in the properties will
    # also be merged.
    #
    # @param props [Hash] the properties to add
    # @return [Gemstash::Resource] self for chaining purposes
    def update_properties(props)
      load_properties(true)

      deep_merge = proc do |_, old_value, new_value|
        if old_value.is_a?(Hash) && new_value.is_a?(Hash)
          old_value.merge(new_value, &deep_merge)
        else
          new_value
        end
      end

      props = properties.merge(props || {}, &deep_merge)
      save_properties(properties.merge(props || {}))
      self
    end

    # Check if the metadata properties includes the +keys+. The +keys+ represent
    # a nested path in the properties to check.
    #
    # Examples:
    #
    #   resource = Gemstash::Storage.for("x").resource("y")
    #   resource.save({ file: "content" }, foo: "one", bar: { baz: "qux" })
    #   resource.has_property?(:foo)       # true
    #   resource.has_property?(:bar, :baz) # true
    #   resource.has_property?(:missing)   # false
    #   resource.has_property?(:foo, :bar) # false
    #
    # @param keys [Array<Object>] one or more keys pointing to a property
    # @return [Boolean] whether the nested keys points to a valid property
    def property?(*keys)
      keys.inject(node: properties, result: true) do |memo, key|
        if memo[:result]
          memo[:result] = memo[:node].is_a?(Hash) && memo[:node].include?(key)
          memo[:node] = memo[:node][key] if memo[:result]
        end

        memo
      end[:result]
    end

    # Delete the content for the given +key+. If the +key+ is the last one for
    # this resource, the metadata properties will be deleted as well. The +key+
    # corresponds to the +content+ key provided to {#save}.
    #
    # The resource will be reset afterwards, clearing any cached content or
    # properties.
    #
    # Does nothing if the key doesn't {#exist?}.
    #
    # @param key [Symbol] the key of the content to delete
    # @return [Gemstash::Resource] self for chaining purposes
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

    def load(key)
      raise "Resource #{@name} has no #{key.inspect} content to load" unless exist?(key)
      load_properties # Ensures storage version is checked
      @content ||= {}
      @content[key] = read_file(content_filename(key))
    end

    def load_properties(force = false)
      return if @properties && !force
      return unless File.exist?(properties_filename)
      @properties = YAML.load_file(properties_filename) || {}
      check_resource_version
    end

    def check_resource_version
      version = @properties[:gemstash_resource_version]
      return if version <= Gemstash::Resource::VERSION
      reset
      raise Gemstash::Resource::VersionTooNew.new(name, folder, version)
    end

    def reset
      @content = nil
      @properties = nil
    end

    def content?
      return false unless Dir.exist?(@folder)
      entries = Dir.entries(@folder).reject {|file| file =~ /\A\.\.?\z/ || file == "properties.yaml" }
      !entries.empty?
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
      props = { gemstash_resource_version: Gemstash::Resource::VERSION }.merge(props)
      store(properties_filename, props.to_yaml)
      @properties = props
    end

    def store(filename, content)
      FileUtils.mkpath(@folder) unless Dir.exist?(@folder)
      save_file(filename) { content }
    end

    def save_file(filename)
      content = yield
      gemstash_env.atomic_write(filename) {|f| f.write(content) }
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
