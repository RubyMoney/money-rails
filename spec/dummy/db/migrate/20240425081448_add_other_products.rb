class AddOtherProducts < ActiveRecord::Migration[7.0]
  def change
    create_table "other_products", force: :cascade do |t|
      t.string "currency"
      t.integer "price_cents"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
