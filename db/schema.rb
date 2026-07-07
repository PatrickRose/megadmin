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

ActiveRecord::Schema[8.1].define(version: 2026_07_06_213842) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at"
    t.datetime "failed_at"
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at"
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "event_signups", force: :cascade do |t|
    t.datetime "brief_emailed_at"
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "event_id"
    t.string "name"
    t.bigint "role_id"
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["event_id"], name: "index_event_signups_on_event_id"
    t.index ["role_id"], name: "index_event_signups_on_role_id"
    t.index ["team_id"], name: "index_event_signups_on_team_id"
  end

  create_table "events", force: :cascade do |t|
    t.text "additional_info"
    t.datetime "created_at", null: false
    t.datetime "date", precision: nil
    t.text "description"
    t.boolean "draft"
    t.string "google_maps_link"
    t.string "location"
    t.string "name"
    t.bigint "organiser_id"
    t.datetime "updated_at", null: false
    t.index ["organiser_id"], name: "index_events_on_organiser_id"
  end

  create_table "organiser_to_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "event_id"
    t.bigint "organiser_id"
    t.boolean "read_only"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_organiser_to_events_on_event_id"
    t.index ["organiser_id"], name: "index_organiser_to_events_on_organiser_id"
  end

  create_table "organisers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_organisers_on_email", unique: true
    t.index ["reset_password_token"], name: "index_organisers_on_reset_password_token", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.bigint "event_id"
    t.string "name"
    t.bigint "team_id", null: false
    t.index ["event_id"], name: "index_roles_on_event_id"
    t.index ["name", "team_id"], name: "index_roles_on_name_and_team_id", unique: true
    t.index ["name"], name: "index_roles_on_name"
    t.index ["team_id"], name: "index_roles_on_team_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "teams", force: :cascade do |t|
    t.bigint "event_id"
    t.string "name"
    t.index ["event_id", "name"], name: "index_teams_on_event_id_and_name", unique: true
    t.index ["event_id"], name: "index_teams_on_event_id"
    t.index ["name"], name: "index_teams_on_name"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "events", "organisers"
  add_foreign_key "roles", "teams"
end
