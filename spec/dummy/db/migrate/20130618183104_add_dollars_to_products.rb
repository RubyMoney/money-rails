class AddDollarsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :dollars, :decimal, :precision => 8, :scale => 2, :default => 0.00
  end
end
