class AddSpecialPriceToProducts < ActiveRecord::Migration
  def change
    add_column :products, :special_price_cents, :integer
  end
end
