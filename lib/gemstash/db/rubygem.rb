require "gemstash"

module Gemstash
  module DB
    # Sequel model for rubygems table.
    class Rubygem < Sequel::Model
      def self.find_id(name)
        record = self[name: name]
        record.id if record
      end

      def self.find_or_insert(spec)
        gem_id = find_id(spec.name)
        return gem_id if gem_id
        new(name: spec.name).tap(&:save).id
      end
    end
  end
end
