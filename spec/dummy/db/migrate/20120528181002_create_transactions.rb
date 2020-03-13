class CreateTransactions < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    create_table :transactions do |t|
      t.integer :amount_cents
      t.integer :tax_cents
      t.string :currency

      t.timestamps
    end
  end
end
