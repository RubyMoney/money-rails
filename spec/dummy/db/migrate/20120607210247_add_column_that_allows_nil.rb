class AddColumnThatAllowsNil < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :optional_price_cents, :integer
  end
end
