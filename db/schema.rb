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

ActiveRecord::Schema[7.2].define(version: 2026_05_01_151332) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "journal_corrections", force: :cascade do |t|
    t.bigint "journal_id", null: false
    t.bigint "user_id", null: false
    t.text "original_text", null: false
    t.text "rewritten_text", null: false
    t.json "strengths"
    t.json "mistake_patterns"
    t.text "advice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "native_phrases"
    t.index ["journal_id"], name: "index_journal_corrections_on_journal_id"
    t.index ["user_id"], name: "index_journal_corrections_on_user_id"
  end

  create_table "journals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "posted_date", null: false
    t.integer "mood"
    t.string "title"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tone"
    t.index ["user_id"], name: "index_journals_on_user_id"
  end

  create_table "mistakes", force: :cascade do |t|
    t.bigint "journal_id", null: false
    t.bigint "user_id", null: false
    t.text "original_text", null: false
    t.text "corrected_text"
    t.text "explanation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mistake_type"
    t.bigint "journal_correction_id"
    t.jsonb "learning_points", default: {}, null: false
    t.index ["journal_correction_id"], name: "index_mistakes_on_journal_correction_id"
    t.index ["journal_id"], name: "index_mistakes_on_journal_id"
    t.index ["user_id"], name: "index_mistakes_on_user_id"
  end

  create_table "notification_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "reminder_enabled", default: false
    t.time "notification_time"
    t.integer "scene_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_settings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "journal_corrections", "journals"
  add_foreign_key "journal_corrections", "users"
  add_foreign_key "journals", "users"
  add_foreign_key "mistakes", "journal_corrections"
  add_foreign_key "mistakes", "journals"
  add_foreign_key "mistakes", "users"
  add_foreign_key "notification_settings", "users"
end
