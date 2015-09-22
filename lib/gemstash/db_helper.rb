module Gemstash
  #:nodoc:
  class DBHelper
    def find_or_insert_rubygem(name)
      row = Gemstash::Env.db[:rubygems][:name => name]
      return row[:id] if row
      Gemstash::Env.db[:rubygems].insert(
        :name => name,
        :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
        :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
    end
  end
end
