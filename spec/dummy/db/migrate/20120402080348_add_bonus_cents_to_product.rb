class AddBonusCentsToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :bonus_cents, :integer

  end
end
