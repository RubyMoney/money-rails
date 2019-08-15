class AddPrecisionUnitCostToProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :unit_cost_cents, :decimal
  end
end
