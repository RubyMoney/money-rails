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

  def insert_version(gem_id, number, platform: "ruby", indexed: true, prerelease: false)
    gem_name = Gemstash::Env.current.db[:rubygems][:id => gem_id][:name]

    if platform == "ruby"
      storage_id = "#{gem_name}-#{number}"
    else
      storage_id = "#{gem_name}-#{number}-#{platform}"
    end

    Gemstash::Env.current.db[:versions].insert(
      :rubygem_id => gem_id,
      :number => number,
      :platform => platform,
      :full_name => "#{gem_name}-#{number}-#{platform}",
      :storage_id => storage_id,
      :indexed => indexed,
      :prerelease => prerelease,
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
