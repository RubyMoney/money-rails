require "rubygems/package"
require "stringio"

module Gemstash
  #:nodoc:
  class GemPusher
    def initialize(content)
      @content = content
    end

    def push
      save_to_database
    end

  private

    def gem
      @gem ||= ::Gem::Package.new(StringIO.new(@content))
    end

    def save_to_database
      spec = gem.spec

      Gemstash::Env.db.transaction do
        gem_id = Gemstash::Env.db[:rubygems].insert(
          :name => spec.name,
          :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
          :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)

        version_id = Gemstash::Env.db[:versions].insert(
          :rubygem_id => gem_id,
          :number => spec.version.to_s,
          :platform => spec.platform,
          :indexed => true,
          :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
          :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)

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
end
