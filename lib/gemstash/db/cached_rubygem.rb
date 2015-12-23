require "gemstash"

module Gemstash
  module DB
    # Sequel model for cached_rubygems table.
    class CachedRubygem < Sequel::Model
      def self.store(upstream, gem_name, resource_type)
        db.transaction do
          upstream_id = Gemstash::DB::Upstream.find_or_insert(upstream)
          record = self[upstream_id: upstream_id, name: gem_name.name, resource_type: resource_type.to_s]
          return record.id if record
          new(upstream_id: upstream_id, name: gem_name.name, resource_type: resource_type.to_s).tap(&:save).id
        end
      end
    end
  end
end
