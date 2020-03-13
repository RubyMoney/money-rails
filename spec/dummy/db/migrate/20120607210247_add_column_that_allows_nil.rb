class AddColumnThatAllowsNil < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :optional_price_cents, :integer
  end
end
