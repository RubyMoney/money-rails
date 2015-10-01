Sequel.migration do
  change do
    create_table :authorizations do
      primary_key :id
      String :auth_key, :size => 2056, :null => false
      String :permissions, :size => 255, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      index [:auth_key], :unique => true
    end
  end
end
