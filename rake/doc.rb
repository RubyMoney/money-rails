require "pathname"

# Helper class for running pandoc
class Doc
  def run
    check_for_pandoc
    convert_docs
  end

  def check_for_pandoc
    return if pandoc_exist?
    abort("You need to install pandoc to generate documentation")
  end

  def pandoc_exist?
    ENV["PATH"].split(::File::PATH_SEPARATOR).any? do |file|
      path = ::File.join(file, "pandoc")
      ::File.exist?(path) && ::File.executable?(path)
    end
  end

  def convert_docs
    Dir[root_dir.join("man/*.md")].each do |file|
      file = Doc::File.new(self, file)
      file.export_to_github
      file.export_to_man
    end
  end

  def root_dir
    @root_dir ||= Pathname.new(::File.expand_path("../..", __FILE__))
  end

  # Container for pandoc filter paths
  module Filters
    UPCASE_HEADERS = ::File.expand_path("../doc/upcase_headers.rb", __FILE__)
  end

  # Represents a single documentation file being converted
  class File
    attr_reader :doc, :file, :base_file

    def initialize(doc, file)
      @doc = doc
      @file = file
      @base_file = ::File.basename(file)
    end

    def export_to_github
      export "markdown_github", export_path("docs", to_extension(".md")), Doc::Filters::UPCASE_HEADERS
    end

    def export_to_man
      export "man", export_path("lib/gemstash/man", to_extension("")), Doc::Filters::UPCASE_HEADERS
    end

    def export(format, to_file, *filters)
      filters = filters.map {|filter| "--filter '#{filter}'" }
      system "pandoc -s -f markdown -t #{format} #{filters.join(" ")} -o '#{to_file}' '#{file}'"
    end

    def export_path(dir, filename)
      path = doc.root_dir.join(dir)
      path.mkpath
      path.join(filename)
    end

    def to_extension(ext)
      base_file.sub(/\.[^.]*\z/, ext)
    end
  end
end
