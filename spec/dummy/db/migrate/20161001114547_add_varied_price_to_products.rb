class AddVariedPriceToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :varied_price_cents, :integer, default: 0, null: false
    add_column :products, :varied_price_currency, :string, default: "USD", null: false
    add_column :products, :varied_price_exchanged_at, :datetime
  end
end
