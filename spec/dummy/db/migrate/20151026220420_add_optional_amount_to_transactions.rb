class AddOptionalAmountToTransactions < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :transactions, :optional_amount_cents, :integer
  end
end
