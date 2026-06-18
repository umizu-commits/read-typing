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

ActiveRecord::Schema[8.1].define(version: 2026_06_18_094049) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "articles", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.bigint "user_id"
    t.index ["expires_at"], name: "index_articles_on_expires_at"
    t.index ["url", "user_id"], name: "index_articles_on_url_and_user_id", unique: true
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "typing_results", force: :cascade do |t|
    t.float "accuracy"
    t.bigint "article_id"
    t.text "article_text"
    t.string "article_title"
    t.float "cpm"
    t.datetime "created_at", null: false
    t.integer "elapsed_time"
    t.integer "miss_count"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.float "wpm"
    t.index ["article_id"], name: "index_typing_results_on_article_id"
    t.index ["user_id", "created_at"], name: "index_typing_results_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_typing_results_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "articles", "users"
  add_foreign_key "typing_results", "articles"
  add_foreign_key "typing_results", "users"
end
