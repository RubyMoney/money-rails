class AddReducedPriceToProducts < ActiveRecord::Migration
  def change
    add_column :products, :reduced_price_cents, :integer
    add_column :products, :reduced_price_currency, :string
  end
end
