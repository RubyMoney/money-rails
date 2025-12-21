class AddOptionalAmountToTransactions < ActiveRecord::Migration[7.0]
  def change
    add_column :transactions, :optional_amount_cents, :integer
  end
end
