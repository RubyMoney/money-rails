class AddValidatesMethodAmountCentsToProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :validates_method_amount_cents, :integer
  end
end
