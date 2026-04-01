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

ActiveRecord::Schema[7.2].define(version: 2026_04_01_041223) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "appointments", force: :cascade do |t|
    t.string "name"
    t.integer "age"
    t.string "email"
    t.string "phone"
    t.string "sex"
    t.integer "doctor_id"
    t.integer "package_id"
    t.integer "status", default: 0, null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "duration"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unique_code"
    t.string "google_calendar_id"
    t.boolean "dummy"
    t.string "token"
    t.integer "scheduled_by"
    t.string "phone_number_e164"
    t.index ["token"], name: "index_appointments_on_token", unique: true
  end

  create_table "doctor_packages", force: :cascade do |t|
    t.integer "doctor_id", null: false
    t.integer "package_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id", "package_id"], name: "index_doctor_packages_on_doctor_id_and_package_id", unique: true
    t.index ["doctor_id"], name: "index_doctor_packages_on_doctor_id"
    t.index ["package_id"], name: "index_doctor_packages_on_package_id"
  end

  create_table "doctor_time_blocks", force: :cascade do |t|
    t.integer "doctor_id", null: false
    t.time "starts_at"
    t.time "ends_at"
    t.json "days_of_week", default: [], null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id"], name: "index_doctor_time_blocks_on_doctor_id"
  end

  create_table "doctor_unavailabilities", force: :cascade do |t|
    t.integer "doctor_id", null: false
    t.date "date"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doctor_id"], name: "index_doctor_unavailabilities_on_doctor_id"
  end

  create_table "doctors", force: :cascade do |t|
    t.string "name"
    t.string "specialty"
    t.string "email"
    t.text "available_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "unavailable_dates"
    t.integer "user_id"
    t.index ["user_id"], name: "index_doctors_on_user_id"
  end

  create_table "packages", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.integer "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind"
    t.boolean "featured"
  end

  create_table "phone_bans", force: :cascade do |t|
    t.string "phone_e164", null: false
    t.integer "level", default: 0, null: false
    t.integer "source", default: 0, null: false
    t.string "reason", null: false
    t.boolean "active", default: true, null: false
    t.datetime "expires_at"
    t.integer "trigger_count"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_phone_bans_on_active"
    t.index ["created_by_id"], name: "index_phone_bans_on_created_by_id"
    t.index ["phone_e164"], name: "index_phone_bans_on_phone_e164", unique: true
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
    t.boolean "can_upload_results", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "doctor_packages", "doctors"
  add_foreign_key "doctor_packages", "packages"
  add_foreign_key "doctor_time_blocks", "doctors"
  add_foreign_key "doctor_unavailabilities", "doctors"
  add_foreign_key "doctors", "users"
  add_foreign_key "phone_bans", "users", column: "created_by_id"
end
