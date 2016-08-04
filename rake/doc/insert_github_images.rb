#!/usr/bin/env ruby
require "json"
require "open3"
require "pandoc-filter"

GITHUB_IMAGES = %{[![Build Status](https://travis-ci.org/bundler/gemstash.svg?branch=master)](https://travis-ci.org/bundler/gemstash)

<p align="center"><img src="gemstash.png" /></p>}

def github_images_json
  pandoc_results = nil

  Open3.popen2("pandoc -f markdown_github -t json") do |stdin, stdout, wait_thr|
    stdin.write(GITHUB_IMAGES)
    stdin.close
    pandoc_results = stdout.read
    raise "Failure from pandoc while building replacement JSON!" unless wait_thr.value.success?
  end

  raise "Invalid results!" unless pandoc_results
  pandoc_results = JSON.parse(pandoc_results)
  pandoc_results.delete_if {|x| x.is_a?(Hash) && x.include?("unMeta") }
  pandoc_results = pandoc_results.first if pandoc_results.is_a?(Array) && pandoc_results.size == 1
  pandoc_results
end

found = false

PandocFilter.filter do |type, value, _format, _meta|
  next unless type == "Header"
  next unless value[2] == [{ "t" => "Str", "c" => "Gemstash" }]
  next if found
  found = true
  github_images_json
end
