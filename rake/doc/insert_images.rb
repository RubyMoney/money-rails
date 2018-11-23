#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "pandoc_object_filters"

HTML_IMAGES = %(<p align="center"><img src="gemstash.png" /></p>)
GITHUB_IMAGES = %([![Build Status][TRAVIS_IMG]][TRAVIS] [![Code Climate][CODE_CLIMATE_IMG]][CODE_CLIMATE]

[TRAVIS_IMG]: https://travis-ci.org/bundler/gemstash.svg?branch=master
[TRAVIS]: https://travis-ci.org/bundler/gemstash
[CODE_CLIMATE_IMG]: https://codeclimate.com/github/bundler/gemstash/badges/gpa.svg
[CODE_CLIMATE]: https://codeclimate.com/github/bundler/gemstash

<p align="center"><img src="gemstash.png" /></p>)

def images_json(markdown)
  pandoc_results = nil

  Open3.popen2("pandoc -f markdown_github -t json") do |stdin, stdout, wait_thr|
    stdin.write(markdown)
    stdin.close
    pandoc_results = stdout.read
    raise "Failure from pandoc while building replacement JSON!" unless wait_thr.value.success?
  end

  raise "Invalid results!" unless pandoc_results

  pandoc_results = JSON.parse(pandoc_results)
  pandoc_results = PandocObjectFilters::Element::Document.new(pandoc_results)
  pandoc_results = pandoc_results.contents

  if pandoc_results.is_a?(Array) && pandoc_results.size == 1
    pandoc_results.first
  else
    pandoc_results
  end
end

found = false

filter = PandocObjectFilters::Filter.new

filter.filter! do |element|
  next if found
  next unless %w[html markdown_github].include?(filter.format)
  next unless filter.doc.meta["insert_images"] && filter.doc.meta["insert_images"].value
  next unless element.is_a?(PandocObjectFilters::Element::Header)
  next unless element.elements.first.is_a?(PandocObjectFilters::Element::Str)
  next unless element.elements.first.value == "Gemstash"

  found = true

  case filter.format
  when "markdown_github"
    result = images_json(GITHUB_IMAGES)
    # Add a newline at the end to preserve the fix in commit bc811ec5030a978f002b552f772a82ec96606db9
    result << PandocObjectFilters::Element::Para.new
    result
  when "html"
    images_json(HTML_IMAGES)
  end
end
