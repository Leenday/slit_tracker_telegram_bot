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

ActiveRecord::Schema.define(version: 2022_05_15_061424) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "reception_records", force: :cascade do |t|
    t.integer "chat_id"
    t.string "daily_status_reception"
    t.string "potion_characteristics"
    t.integer "potion_pressing_count"
    t.string "potion_side_effects"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reminders", force: :cascade do |t|
    t.integer "chat_id"
    t.time "remind_at"
    t.text "worker_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
