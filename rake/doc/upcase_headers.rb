#!/usr/bin/env ruby
require "pandoc-filter"

def upcase_if_str_node(node)
  if node["t"] == "Str"
    PandocElement.Str(node["c"].upcase)
  else
    node
  end
end

PandocFilter.filter do |type, value, _format, _meta|
  next unless type == "Header"
  PandocElement.Header(value[0], value[1], value[2].map {|node| upcase_if_str_node(node) })
end
