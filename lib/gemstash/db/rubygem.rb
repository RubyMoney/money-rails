# frozen_string_literal: true

require "gemstash"

module Gemstash
  module DB
    # Sequel model for rubygems table.
    class Rubygem < Sequel::Model
      def self.find_or_insert(spec)
        record = self[name: spec.name]
        return record.id if record

        new(name: spec.name).tap(&:save).id
      end
    end
  end
end
