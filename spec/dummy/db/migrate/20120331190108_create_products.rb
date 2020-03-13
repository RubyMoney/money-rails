class CreateProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    create_table :products do |t|
      t.integer :price_cents
      t.integer :discount

      t.timestamps
    end
  end
end
