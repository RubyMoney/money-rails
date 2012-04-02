class AddBonusCentsToProduct < ActiveRecord::Migration
  def change
    add_column :products, :bonus_cents, :integer

  end
end
