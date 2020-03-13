class AddSpecialPriceToProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :special_price_cents, :integer
  end
end
