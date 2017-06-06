class AddOptionalAmountToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :optional_amount_cents, :integer
  end
end
