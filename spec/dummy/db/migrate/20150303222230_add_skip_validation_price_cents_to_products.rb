class AddSkipValidationPriceCentsToProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :skip_validation_price_cents, :string
  end
end
