class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.integer :amount_cents
      t.integer :tax_cents
      t.string :currency

      t.timestamps
    end
  end
end
