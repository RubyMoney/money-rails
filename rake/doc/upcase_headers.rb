#!/usr/bin/env ruby
# frozen_string_literal: true

require "pandoc_object_filters"

filter = PandocObjectFilters::Filter.new

filter.filter do |element|
  next unless filter.format == "man"
  next unless element.is_a?(PandocObjectFilters::Element::Header)

  element.elements.each {|e| e.value.upcase! if e.is_a?(PandocObjectFilters::Element::Str) }
end
