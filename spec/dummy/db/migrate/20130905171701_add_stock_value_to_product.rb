class AddStockValueToProduct < ActiveRecord::Migration
  def change
    add_money :products, :stock_value
  end
end
