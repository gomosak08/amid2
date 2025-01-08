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

ActiveRecord::Schema[7.2].define(version: 2024_12_10_210409) do
  create_table "appointments", force: :cascade do |t|
    t.string "name"
    t.integer "age"
    t.string "email"
    t.string "phone"
    t.string "sex"
    t.integer "doctor_id"
    t.integer "package_id"
    t.string "status"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "duration"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "appointment_date"
    t.string "unique_code"
    t.string "google_calendar_id"
    t.boolean "dummy"
  end

  create_table "doctors", force: :cascade do |t|
    t.string "name"
    t.string "specialty"
    t.string "email"
    t.text "available_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "unavailable_dates"
  end

  create_table "packages", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "image"
    t.decimal "price"
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "role"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
