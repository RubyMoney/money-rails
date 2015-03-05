class AddSkipValidationPriceCentsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :skip_validation_price_cents, :string
  end
end
