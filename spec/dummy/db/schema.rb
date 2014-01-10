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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140110194016) do

  create_table "dummy_products", :force => true do |t|
    t.string   "currency"
    t.integer  "price_cents"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "items", :force => true do |t|
  end

  create_table "products", :force => true do |t|
    t.integer  "price_cents"
    t.integer  "discount"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "bonus_cents"
    t.integer  "optional_price_cents"
    t.integer  "sale_price_amount",             :default => 0, :null => false
    t.string   "sale_price_currency_code"
    t.integer  "price_in_a_range_cents"
    t.integer  "validates_method_amount_cents"
  end

  create_table "services", :force => true do |t|
    t.integer  "charge_cents"
    t.integer  "discount_cents"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "transactions", :force => true do |t|
    t.integer  "amount_cents"
    t.integer  "tax_cents"
    t.string   "currency"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

end
