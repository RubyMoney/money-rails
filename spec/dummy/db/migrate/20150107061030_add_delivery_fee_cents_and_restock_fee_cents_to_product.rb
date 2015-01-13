class AddDeliveryFeeCentsAndRestockFeeCentsToProduct < ActiveRecord::Migration
  def change
    add_column :products, :delivery_fee_cents, :integer
    add_column :products, :restock_fee_cents, :integer
  end
end
