# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :upstreams do
      primary_key :id
      String :uri, size: 191, null: false
      String :host_id, size: 191, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:uri], unique: true
      index [:host_id], unique: true
    end

    create_table :cached_rubygems do
      primary_key :id
      Integer :upstream_id, null: false
      String :name, size: 191, null: false
      String :resource_type, size: 191, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index %i[upstream_id resource_type name], unique: true
      index [:name]
    end
  end
end
