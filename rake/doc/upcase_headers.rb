#!/usr/bin/env ruby
require "pandoc_object_filters"

filter = PandocObjectFilters::Filter.new

filter.filter do |element|
  next unless filter.format == "man"
  next unless element.is_a?(PandocObjectFilters::Element::Header)
  element.elements.each {|e| e.value.upcase! if e.is_a?(PandocObjectFilters::Element::Str) }
end
