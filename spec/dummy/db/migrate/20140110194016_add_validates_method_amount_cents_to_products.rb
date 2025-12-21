class AddValidatesMethodAmountCentsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :validates_method_amount_cents, :integer
  end
end
