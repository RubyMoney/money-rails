class AddPriceInARangeCentsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :price_in_a_range_cents, :integer
  end
end
