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

ActiveRecord::Schema.define(version: 20130912033141) do

  create_table "items", force: true do |t|
    t.string   "buy_num"
    t.string   "item_num"
    t.text     "description"
    t.string   "qty"
    t.string   "unit"
    t.string   "option"
    t.string   "period_of_performance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "requirements", force: true do |t|
    t.string   "buy_num"
    t.string   "title"
    t.text     "specification"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "solicitations", force: true do |t|
    t.string   "buy_num"
    t.string   "rev"
    t.string   "title"
    t.string   "buyer"
    t.string   "end_time"
    t.string   "set_aside_req"
    t.string   "location"
    t.string   "category"
    t.string   "subcategory"
    t.string   "naics"
    t.string   "fbo_solicitation"
    t.string   "recovery_act"
    t.string   "delivery"
    t.string   "bid_delivery_days"
    t.string   "repost_reason"
    t.string   "solicitation_num"
    t.string   "revised_at"
    t.string   "removed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "terms", force: true do |t|
    t.string   "buy_num"
    t.string   "title"
    t.text     "specification"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
