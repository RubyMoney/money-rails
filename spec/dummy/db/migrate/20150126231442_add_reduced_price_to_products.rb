class AddReducedPriceToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :reduced_price_cents, :integer
    add_column :products, :reduced_price_currency, :string
  end
end
