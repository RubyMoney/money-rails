class AddPriceInARangeCentsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :price_in_a_range_cents, :integer
  end
end
