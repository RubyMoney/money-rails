# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151026220420) do

  create_table "dummy_products", force: :cascade do |t|
    t.string   "currency"
    t.integer  "price_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: :cascade do |t|
    t.integer  "price_cents"
    t.integer  "discount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bonus_cents"
    t.integer  "optional_price_cents"
    t.integer  "sale_price_amount",             default: 0, null: false
    t.string   "sale_price_currency_code"
    t.integer  "price_in_a_range_cents"
    t.integer  "validates_method_amount_cents"
    t.integer  "aliased_cents"
    t.integer  "delivery_fee_cents"
    t.integer  "restock_fee_cents"
    t.integer  "reduced_price_cents"
    t.string   "reduced_price_currency"
    t.integer  "special_price_cents"
    t.integer  "lambda_price_cents"
    t.string   "skip_validation_price_cents"
  end

  create_table "services", force: :cascade do |t|
    t.integer  "charge_cents"
    t.integer  "discount_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer  "amount_cents"
    t.integer  "tax_cents"
    t.string   "currency"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "optional_amount_cents"
  end

end
