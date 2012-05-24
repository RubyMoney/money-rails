class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.integer :charge_cents
      t.integer :discount_cents

      t.timestamps
    end
  end
end
