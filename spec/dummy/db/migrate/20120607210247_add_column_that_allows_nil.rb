class AddColumnThatAllowsNil < ActiveRecord::Migration
  def change
    add_column :products, :optional_price_cents, :integer
  end
end
