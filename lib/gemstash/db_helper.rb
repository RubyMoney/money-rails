module Gemstash
  #:nodoc:
  class DBHelper
    def find_or_insert_rubygem(spec)
      row = Gemstash::Env.db[:rubygems][:name => spec.name]
      return row[:id] if row
      Gemstash::Env.db[:rubygems].insert(
        :name => spec.name,
        :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
        :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
    end

    def find_version(gem_id, spec)
      Gemstash::Env.db[:versions][
        :rubygem_id => gem_id,
        :number => spec.version.to_s,
        :platform => spec.platform]
    end

    def insert_version(gem_id, spec, indexed = true)
      Gemstash::Env.db[:versions].insert(
        :rubygem_id => gem_id,
        :number => spec.version.to_s,
        :platform => spec.platform,
        :indexed => indexed,
        :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
        :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
    end

    def insert_dependencies(version_id, spec)
      spec.runtime_dependencies.each do |dep|
        requirements = dep.requirement.requirements
        requirements = requirements.map {|r| "#{r.first} #{r.last}" }
        requirements = requirements.join(", ")
        Gemstash::Env.db[:dependencies].insert(
          :version_id => version_id,
          :rubygem_name => dep.name,
          :requirements => requirements,
          :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
          :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
      end
    end
  end
end
