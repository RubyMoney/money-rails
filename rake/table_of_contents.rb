require "pathname"

# Helper class for generating the table of contents in markdown files.
class TableOfContents
  attr_reader :toc_dir, :toc, :docs_dir

  def initialize
    @toc_dir = Pathname.new(File.expand_path("../../tmp", __FILE__))
    @toc = @toc_dir.join("gh-md-toc")
    @docs_dir = Pathname.new(File.expand_path("../../docs", __FILE__))
  end

  def run
    cache_toc_script
    update_toc("reference.md")
  end

  def update_toc(doc)
    doc = docs_dir.join(doc)
    old_contents = File.read(doc)
    old_contents.sub!(/\A.*?^---$/m, "---")
    File.write(doc, old_contents)
    toc_contents = `"#{toc}" "#{doc}"`
    toc_contents.sub!(/Created by.*$/, "")
    File.write(doc, "#{toc_contents}\n#{old_contents}")
  end

  def cache_toc_script
    return if toc.exist?
    require "open-uri"
    toc_contents = open("https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc", &:read)
    Dir.mkdir(toc_dir) unless toc_dir.exist?
    File.write(toc, toc_contents)
    File.chmod(0776, toc)
  end
end
