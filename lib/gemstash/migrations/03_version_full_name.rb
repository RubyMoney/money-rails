Sequel.migration do
  change do
    add_column :versions, :full_name, String

    self["SELECT rubygems.name, versions.id, versions.number, versions.platform
          FROM versions JOIN rubygems ON rubygems.id = versions.rubygem_id"].each do |row|
      full_name = "#{row[:name]}-#{row[:number]}-#{row[:platform]}"
      self[:versions].where(:id => row[:id]).update(:full_name => full_name)
    end

    alter_table(:versions) do
      set_column_not_null :full_name
      add_index [:full_name], :unique => true
    end
  end
end
