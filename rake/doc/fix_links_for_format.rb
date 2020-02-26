#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "pandoc_object_filters"
require "pathname"

FILTER = PandocObjectFilters::Filter.new

# Utility class to construct a link to another Pandoc generated document in the
# correct path to the target format.
class DocLinkUrl
  def initialize(url)
    @file = url[/\A[^#]*/]
    @heading = url[/#(.*\z)/, 1]
  end

  def file_path
    File.expand_path("../../../man/#{@file}", __FILE__)
  end

  def path
    @path ||= path_to(doc)
  end

  def doc
    @doc ||=
      begin
        json_doc = JSON.parse(`pandoc -f markdown -t json "#{file_path}"`)
        PandocObjectFilters::Element::Document.new(json_doc)
      end
  end

  def filename
    @filename ||=
      begin
        meta = doc.meta["#{FILTER.format}_link_name"]
        default = File.basename(@file).sub(/\.md\z/, format_extension)
        extract_meta(meta, default)
      end
  end

  def format_extension
    case FILTER.format
    when "gfm"
      ".md"
    when "html"
      ".html"
    when "man"
      ""
    else
      raise "Unknown format: #{FILTER.format}"
    end
  end

  def relative_path
    Pathname.new(path).join(filename)
  end

  def heading
    "##{@heading}" unless @heading.to_s.empty?
  end

  def to_s
    case FILTER.format
    when "gfm"
      "#{relative_path}#{heading}"
    when "html"
      "#{relative_path.sub(/\.md\z/, ".html")}#{heading}"
    when "man"
      "gemstash help #{filename.sub(/\Agemstash-/, "")}"
    else
      raise "Unknown format: #{FILTER.format}"
    end
  end
end

def current_path
  @current_path ||= path_to(FILTER.doc)
end

def path_to(doc)
  default = FILTER.format == "gfm" ? "docs" : "."
  extract_meta(doc.meta["#{FILTER.format}_link_path"], default)
end

def extract_meta(meta, default = nil)
  return default unless meta
  return meta.value if meta.is_a?(PandocObjectFilters::Element::MetaString)
  raise "Unknown meta type: #{meta.class}" unless meta.is_a?(PandocObjectFilters::Element::MetaInlines)

  meta.elements.map do |element|
    if element.is_a?(PandocObjectFilters::Element::Space)
      " "
    else
      element.value
    end
  end.join
end

FILTER.filter do |element|
  next unless element.is_a?(PandocObjectFilters::Element::Link)

  match = %r{\A\./(gemstash-.*)\z}.match(element.target.url)
  next unless match

  element.target.url = DocLinkUrl.new(match[1]).to_s
end
