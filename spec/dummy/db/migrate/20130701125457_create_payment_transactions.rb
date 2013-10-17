class CreatePaymentTransactions < ActiveRecord::Migration
  def change
    create_table :payment_transactions do |t|
      t.integer :acquirer_id
      t.integer :amount_cents
      t.string :amount_currency
      t.integer :tax_cents
      t.string :tax_currency

      t.timestamps
    end
  end
end
