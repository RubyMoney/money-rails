require "gemstash"

module Gemstash
  #:nodoc:
  class DBHelper
    include Gemstash::Env::Helper

    def find_rubygem_id(name)
      row = gemstash_env.db[:rubygems][:name => name]
      row[:id] if row
    end

    def find_or_insert_rubygem(spec)
      gem_id = find_rubygem_id(spec.name)
      return gem_id if gem_id
      gemstash_env.db[:rubygems].insert(
        :name => spec.name,
        :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
        :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
    end

    def find_version_by_spec(gem_id, spec)
      gemstash_env.db[:versions][
        :rubygem_id => gem_id,
        :number => spec.version.to_s,
        :platform => spec.platform]
    end

    def find_version_by_full_name(full_name)
      result = gemstash_env.db[:versions][:full_name => full_name]
      return result if result
      # Try again with the default platform, in case it is implied
      gemstash_env.db[:versions][:full_name => "#{full_name}-ruby"]
    end

    def insert_version(gem_id, spec, indexed = true)
      gem_name = gemstash_env.db[:rubygems][:id => gem_id][:name]
      gemstash_env.db[:versions].insert(
        :rubygem_id => gem_id,
        :number => spec.version.to_s,
        :platform => spec.platform,
        :full_name => "#{gem_name}-#{spec.version}-#{spec.platform}",
        :indexed => indexed,
        :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
        :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
    end

    def deindex_version(version_id)
      gemstash_env.db[:versions].where(:id => version_id).update(
        :indexed => false,
        :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
    end

    def insert_dependencies(version_id, spec)
      spec.runtime_dependencies.each do |dep|
        requirements = dep.requirement.requirements
        requirements = requirements.map {|r| "#{r.first} #{r.last}" }
        requirements = requirements.join(", ")
        gemstash_env.db[:dependencies].insert(
          :version_id => version_id,
          :rubygem_name => dep.name,
          :requirements => requirements,
          :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
          :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
      end
    end

    def find_dependencies(gems)
      results = gemstash_env.db["
        SELECT rubygem.name,
               version.number, version.platform,
               dependency.rubygem_name, dependency.requirements
        FROM rubygems rubygem
        JOIN versions version
          ON version.rubygem_id = rubygem.id
        LEFT JOIN dependencies dependency
          ON dependency.version_id = version.id
        WHERE rubygem.name IN ?
          AND version.indexed = ?", gems.to_a, true].to_a
      results.group_by {|r| r[:name] }.each do |gem, rows|
        requirements = rows.group_by {|r| [r[:number], r[:platform]] }

        value = requirements.map do |version, r|
          deps = r.map {|x| [x[:rubygem_name], x[:requirements]] }
          deps = [] if deps.size == 1 && deps.first.first.nil?

          {
            :name => gem,
            :number => version.first,
            :platform => version.last,
            :dependencies => deps
          }
        end

        yield(gem, value)
      end
    end
  end
end
