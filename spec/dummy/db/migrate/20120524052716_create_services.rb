class CreateServices < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    create_table :services do |t|
      t.integer :charge_cents
      t.integer :discount_cents

      t.timestamps
    end
  end
end
