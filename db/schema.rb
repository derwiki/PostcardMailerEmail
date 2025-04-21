# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_21_220333) do
  create_table "addresses", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "nickname"
    t.string "name"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "postcards", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "address_id", null: false
    t.string "status"
    t.json "response_data"
    t.string "image_url"
    t.string "message"
    t.boolean "dryrun"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "print_record_id"
    t.json "directmailers_events", default: []
    t.index ["address_id"], name: "index_postcards_on_address_id"
    t.index ["print_record_id"], name: "index_postcards_on_print_record_id", unique: true
    t.index ["user_id"], name: "index_postcards_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "postcards", "addresses"
  add_foreign_key "postcards", "users"
end
