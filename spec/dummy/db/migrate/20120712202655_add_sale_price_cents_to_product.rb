class AddSalePriceCentsToProduct < ActiveRecord::Migration
  def change
    add_column :products, :sale_price_amount, :integer,
               :default => 0, :null => false
    add_column :products, :sale_price_currency_code, :string
  end
end
