class CreateDummyProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :dummy_products do |t|
      t.string :currency
      t.integer :price_cents

      t.timestamps
    end
  end
end
