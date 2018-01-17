#!/usr/bin/env ruby
require "open3"
require "pandoc_object_filters"

# This filter fixes a problem with Pandoc that doesn't introduce line breaks in
# GitHub Markdown via 2 spaces at the end, so some documentation doesn't get
# formatted properly.

# First test that the problem still exists
PANDOC_MD_INPUT = "Multiple lines\\\nwith explicit\\\nline breaks".freeze
INVALID_EXPECTED_MD_OUTPUT = "Multiple lines\nwith explicit\nline breaks\n".freeze

pandoc_results = nil

Open3.popen2("pandoc -f markdown -t markdown_github") do |stdin, stdout, wait_thr|
  stdin.write(PANDOC_MD_INPUT)
  stdin.close
  pandoc_results = stdout.read
  raise "Failure from pandoc while checking for line break problem!" unless wait_thr.value.success?
end

if pandoc_results != INVALID_EXPECTED_MD_OUTPUT
  raise "Pandoc may have fixed incorrect line break output for GitHub Markdown"
end

filter = PandocObjectFilters::Filter.new

filter.filter do |element|
  next unless filter.format == "markdown_github"
  next unless element.is_a?(PandocObjectFilters::Element::Block)
  next unless element.respond_to?(:elements)
  next unless element.elements.find {|e| e.is_a?(PandocObjectFilters::Element::LineBreak) }
  spaces_indexes_to_add = []

  element.elements.each_with_index do |e, i|
    next unless e.is_a?(PandocObjectFilters::Element::LineBreak)

    if i.zero?
      STDERR.puts "[#{File.basename(__FILE__)}][WARNING] Found line break at the beginning of a block!"
      next
    end

    previous = element.elements[i - 1]

    unless previous.is_a?(PandocObjectFilters::Element::Inline)
      STDERR.puts "[#{File.basename(__FILE__)}][WARNING] Previous element to line break was not an inline!"
      next
    end

    if previous.is_a?(PandocObjectFilters::Element::Str)
      previous.value = "#{previous.value}  "
    else
      spaces_indexes_to_add << i
    end
  end

  spaces_indexes_to_add.reverse_each do |index|
    element.elements.insert index, PandocObjectFilters::Element::Str.new("  ")
  end
end
