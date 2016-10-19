require "fileutils"
require "pathname"

# Helper class for running pandoc
class Doc
  def run
    check_for_pandoc
    check_for_groff
    convert_docs
  end

  def check_for_pandoc
    return if which?("pandoc")
    abort("You need to install pandoc to generate documentation")
  end

  def check_for_groff
    return if which?("groff")
    abort("You need to install groff to generate documentation")
  end

  def which?(exe)
    ENV["PATH"].split(::File::PATH_SEPARATOR).any? do |file|
      path = ::File.join(file, exe)
      ::File.exist?(path) && ::File.executable?(path)
    end
  end

  def convert_docs
    Dir[root_dir.join("man/*.md")].each do |file|
      file = Doc::File.new(self, file)
      file.export_to_github
      file.export_to_man_and_txt
      file.export_to_html
    end

    FileUtils.cp(root_dir.join("gemstash.png"), root_dir.join("html/gemstash.png"))
  end

  def root_dir
    @root_dir ||= Pathname.new(::File.expand_path("../..", __FILE__))
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
      if base_file == "gemstash-readme.7.md"
        path = doc.root_dir.join("README.md")
      else
        path = to_extension(".md")
      end

      export "markdown_github", export_path("docs", path)
    end

    def system(command)
      puts command
      Kernel.system(command)
    end

    def export_to_man_and_txt
      path = export_path("lib/gemstash/man", to_extension(""))
      export "man", path
      system "groff -Wall -mtty-char -mandoc -Tascii #{path} | col -b > #{path}.txt"
    end

    def export_to_html
      if base_file == "gemstash-readme.7.md"
        path = "index.html"
      else
        path = to_extension(".html")
      end

      export "html", export_path("html", path)
    end

    def filters
      %w(insert_github_generation_comment.rb
         insert_images.rb
         upcase_headers.rb
         fix_links_for_format.rb
         fix_github_line_breaks.rb).map do |filter|
        ::File.expand_path("../doc/#{filter}", __FILE__)
      end
    end

    def export(format, to_file)
      filter_args = filters.map {|filter| "--filter '#{filter}'" }
      system "pandoc -s -f markdown -t #{format} #{filter_args.join(" ")} -o '#{to_file}' '#{file}'"
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
