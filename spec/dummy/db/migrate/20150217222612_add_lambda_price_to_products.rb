class AddLambdaPriceToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :lambda_price_cents, :integer
  end
end
