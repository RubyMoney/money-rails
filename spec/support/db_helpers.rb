#:nodoc:
module DBHelpers
  def insert_rubygem(name)
    Gemstash::Env.db[:rubygems].insert(
      :name => name,
      :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
      :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
  end

  def insert_version(gem_id, number, platform = "ruby", indexed = true)
    Gemstash::Env.db[:versions].insert(
      :rubygem_id => gem_id,
      :number => number,
      :platform => platform,
      :indexed => indexed,
      :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
      :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
  end

  def insert_dependency(version_id, gem_name, requirements)
    Gemstash::Env.db[:dependencies].insert(
      :version_id => version_id,
      :rubygem_name => gem_name,
      :requirements => requirements,
      :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
      :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
  end
end
