class AddOtherProducts < (Rails::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    create_table "other_products", force: :cascade do |t|
      t.string "currency"
      t.integer "price_cents"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
