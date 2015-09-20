Sequel.migration do
  change do
    create_table :rubygems do
      primary_key :id
      String :name, :size => 255, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      index [:name], :unique => true
    end

    create_table :versions do
      primary_key :id
      Integer :rubygem_id, :null => false
      String :number, :size => 255, :null => false
      String :platform, :size => 255, :null => false
      TrueClass :indexed, :default => true, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      index [:rubygem_id, :number, :platform], :unique => true
      index [:indexed]
      index [:number]
    end

    create_table :dependencies do
      primary_key :id
      Integer :version_id, :null => false
      Integer :rubygem_id, :null => false
      String :requirements, :size => 255, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      index [:version_id]
      index [:rubygem_id]
    end
  end
end
