# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_07_31_141949) do

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "agreements", force: :cascade do |t|
    t.string "uni"
    t.string "name", null: false
    t.string "email", null: false
    t.string "agreement_version", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["user_id"], name: "index_agreements_on_user_id"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "document_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
  end

  create_table "deposits", force: :cascade do |t|
    t.string "agreement_version"
    t.string "uni"
    t.string "name"
    t.string "email"
    t.string "file_path"
    t.text "title"
    t.text "authors"
    t.text "abstract"
    t.string "url"
    t.string "doi_pmcid"
    t.text "notes"
    t.boolean "archived", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.text "metadata"
    t.string "hyacinth_identifier"
    t.boolean "proxied"
    t.boolean "authenticated"
    t.boolean "current_student"
    t.string "degree_program"
    t.string "academic_advisor"
    t.string "thesis_or_dissertation"
    t.string "degree_earned"
    t.string "embargo_date"
    t.boolean "previously_published"
    t.string "article_version"
    t.text "keywords"
    t.index ["user_id"], name: "index_deposits_on_user_id"
  end

  create_table "email_preferences", force: :cascade do |t|
    t.string "uni", null: false
    t.boolean "unsubscribe"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["uni", "unsubscribe"], name: "index_email_preferences_on_uni_and_unsubscribe"
    t.index ["uni"], name: "index_email_preferences_on_uni", unique: true
  end

  create_table "eventlogs", id: false, force: :cascade do |t|
    t.integer "id"
    t.string "event_name"
    t.string "user_name"
    t.string "uid"
    t.string "ip"
    t.string "session_id"
    t.datetime "timestamp"
  end

  create_table "feature_categories", force: :cascade do |t|
    t.string "field_name", null: false
    t.string "label", null: false
    t.string "thumbnail_url", null: false
    t.float "threshold", default: 80.0
    t.index ["field_name"], name: "index_feature_categories_on_field_name", unique: true
  end

  create_table "featured_search_values", force: :cascade do |t|
    t.string "value", null: false
    t.integer "featured_search_id", null: false
    t.index ["featured_search_id"], name: "index_featured_search_values_on_featured_search_id"
    t.index ["value"], name: "index_featured_search_values_on_value"
  end

  create_table "featured_searches", force: :cascade do |t|
    t.string "slug", null: false
    t.string "label", null: false
    t.integer "priority", default: 0, null: false
    t.string "url"
    t.string "thumbnail_url"
    t.text "description"
    t.integer "feature_category_id", null: false
    t.index ["feature_category_id"], name: "index_featured_searches_on_feature_category_id"
    t.index ["label"], name: "index_featured_searches_on_label"
    t.index ["slug"], name: "index_featured_searches_on_slug", unique: true
  end

  create_table "logvalues", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "eventlog_id"
    t.string "param_name"
    t.string "value"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "doi", null: false
    t.string "kind", null: false
    t.string "email"
    t.string "uni"
    t.datetime "sent_at"
    t.boolean "success", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doi"], name: "index_notifications_on_doi"
  end

  create_table "searches", force: :cascade do |t|
    t.text "query_params"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "site_configurations", force: :cascade do |t|
    t.boolean "downloads_enabled", default: true, null: false
    t.string "downloads_message"
    t.boolean "deposits_enabled", default: true, null: false
    t.string "alert_message"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "singleton_guard"
    t.index "\"singelton_guard\"", name: "index_site_configurations_on_singelton_guard", unique: true
  end

  create_table "statistics", force: :cascade do |t|
    t.string "session_id"
    t.string "event", null: false
    t.string "ip_address"
    t.string "identifier"
    t.string "result"
    t.datetime "at_time", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["at_time"], name: "index_statistics_on_at_time"
    t.index ["event"], name: "index_statistics_on_event"
    t.index ["identifier"], name: "index_statistics_on_identifier"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.datetime "created_at"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "token", null: false
    t.string "scope", null: false
    t.string "contact_email"
    t.text "description"
    t.index ["scope", "token"], name: "index_tokens_on_scope_and_token"
    t.index ["scope"], name: "index_tokens_on_scope"
    t.index ["token"], name: "index_tokens_on_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.boolean "admin"
    t.string "uid", null: false
    t.string "email"
    t.string "crypted_password"
    t.string "persistence_token"
    t.integer "sign_in_count", default: 0, null: false
    t.text "last_search_url"
    t.datetime "last_sign_in_at"
    t.datetime "last_request_at"
    t.datetime "current_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "current_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_request_at"], name: "index_users_on_last_request_at"
    t.index ["persistence_token"], name: "index_users_on_persistence_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agreements", "users"
  add_foreign_key "deposits", "users"
  add_foreign_key "featured_search_values", "featured_searches"
  add_foreign_key "featured_searches", "feature_categories"
end
