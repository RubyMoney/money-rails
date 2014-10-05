class AddAliasedAttrToProducts < ActiveRecord::Migration
  def change
    add_column :products, :aliased_cents, :integer
  end
end
