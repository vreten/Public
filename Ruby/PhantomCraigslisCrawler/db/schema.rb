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

ActiveRecord::Schema.define(version: 20130701041052) do

  create_table "listings", force: true do |t|
    t.string   "userIDs"
    t.string   "cListNumber"
    t.string   "title"
    t.string   "price"
    t.string   "location"
    t.string   "date"
    t.string   "descriptionURL"
    t.text     "pictureURLs"
    t.string   "sellersEmail"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "searches", force: true do |t|
    t.string   "userIDs"
    t.string   "minPrice"
    t.string   "maxPrice"
    t.text     "keywords"
    t.string   "categoryURL"
    t.text     "listingIDs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "firstName"
    t.string   "lastName"
    t.string   "email"
    t.string   "homeURL"
    t.string   "subURL"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
