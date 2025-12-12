class AddAliasedAttrToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :aliased_cents, :integer
  end
end
