Sequel.migration do
  change do
    create_table :health_tests do
      primary_key :id
      String :string
    end
  end
end
