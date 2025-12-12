class AddSkipValidationPriceCentsToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :skip_validation_price_cents, :string
  end
end
