class CreateExchangeRates < ActiveRecord::Migration
  def change
    create_table :exchange_rates do |t|
      t.string :from
      t.string :to
      t.float :rate
    end
  end
end
