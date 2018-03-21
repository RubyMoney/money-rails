class CreateDummyProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    create_table :dummy_products do |t|
      t.string :currency
      t.integer :price_cents

      t.timestamps
    end
  end
end
