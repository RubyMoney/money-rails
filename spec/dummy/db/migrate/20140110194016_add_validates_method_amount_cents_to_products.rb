class AddValidatesMethodAmountCentsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :validates_method_amount_cents, :integer
  end
end
