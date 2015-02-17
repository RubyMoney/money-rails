class CreateGoods < ActiveRecord::Migration
  def change
    create_table :goods do |t|
      t.integer :some_prefix_price_pennies
    end
  end
end
