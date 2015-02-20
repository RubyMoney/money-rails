class AddLambdaPriceToProducts < ActiveRecord::Migration
  def change
    add_column :products, :lambda_price_cents, :integer
  end
end
