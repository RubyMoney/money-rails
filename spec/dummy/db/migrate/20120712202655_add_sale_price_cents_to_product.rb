class AddSalePriceCentsToProduct < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :sale_price_amount, :integer,
               default: 0, null: false
    add_column :products, :sale_price_currency_code, :string
  end
end
