#:nodoc:
module DBHelpers
  def find_rubygem_id(name)
    Gemstash::Env.current.db[:rubygems][:name => name][:id]
  end

  def insert_rubygem(name)
    Gemstash::Env.current.db[:rubygems].insert(
      :name => name,
      :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
      :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
  end

  def insert_version(gem_id, number, platform = "ruby", indexed = true)
    gem_name = Gemstash::Env.current.db[:rubygems][:id => gem_id][:name]
    Gemstash::Env.current.db[:versions].insert(
      :rubygem_id => gem_id,
      :number => number,
      :platform => platform,
      :full_name => "#{gem_name}-#{number}-#{platform}",
      :indexed => indexed,
      :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
      :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
  end

  def insert_dependency(version_id, gem_name, requirements)
    Gemstash::Env.current.db[:dependencies].insert(
      :version_id => version_id,
      :rubygem_name => gem_name,
      :requirements => requirements,
      :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
      :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
  end
end
