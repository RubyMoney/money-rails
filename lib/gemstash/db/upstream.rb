module Gemstash
  module DB
    # Sequel model for upstreams table.
    class Upstream < Sequel::Model
      def self.find_or_insert(upstream)
        record = self[uri: upstream.to_s]
        return record.id if record
        new(uri: upstream.to_s, host_id: upstream.host_id).tap(&:save).id
      end
    end
  end
end
