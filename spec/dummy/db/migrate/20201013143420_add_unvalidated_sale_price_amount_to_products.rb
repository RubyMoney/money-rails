class AddUnvalidatedSalePriceAmountToProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :unvalidated_sale_price_amount, :integer,
      default: 0, null: false
  end
end
