require "gemstash"

module Gemstash
  module DB
    # Sequel model for dependencies table.
    class Dependency < Sequel::Model
      def self.insert_by_spec(version_id, spec)
        spec.runtime_dependencies.each do |dep|
          requirements = dep.requirement.requirements
          requirements = requirements.map {|r| "#{r.first} #{r.last}" }
          requirements = requirements.join(", ")
          create(version_id: version_id,
                 rubygem_name: dep.name,
                 requirements: requirements)
        end
      end

      def self.fetch(gems)
        results = db["
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
end
