class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.integer :amount_cents
      t.integer :tax_cents
      t.string :currency

      t.timestamps
    end
  end
end
