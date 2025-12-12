class AddSpecialPriceToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :special_price_cents, :integer
  end
end
