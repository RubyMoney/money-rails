class AddBonusCentsToProduct < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :bonus_cents, :integer

  end
end
