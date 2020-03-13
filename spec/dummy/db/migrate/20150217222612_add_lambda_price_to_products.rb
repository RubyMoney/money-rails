class AddLambdaPriceToProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :lambda_price_cents, :integer
  end
end
