class AddAliasedAttrToProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    add_column :products, :aliased_cents, :integer
  end
end
