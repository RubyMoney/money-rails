require "gemstash"

module Gemstash
  module DB
    # Sequel model for authorizations table.
    class Authorization < Sequel::Model
      def self.insert_or_update(auth_key, permissions)
        db.transaction do
          record = self[auth_key: auth_key]

          if record
            record.update(permissions: permissions)
          else
            create(auth_key: auth_key, permissions: permissions)
          end
        end
      end
    end
  end
end
