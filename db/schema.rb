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

ActiveRecord::Schema.define(version: 20161031153218) do

  create_table "agreements", force: :cascade do |t|
    t.string   "uni",               limit: 255
    t.string   "name",              limit: 255
    t.string   "email",             limit: 255
    t.string   "agreement_version", limit: 255
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",                 null: false
    t.string   "document_id", limit: 255
    t.string   "title",       limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "user_type",   limit: 255
  end

  create_table "content_blocks", force: :cascade do |t|
    t.string   "title",      limit: 255, null: false
    t.integer  "user_id",                null: false
    t.text     "data"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "content_blocks", ["title"], name: "index_content_blocks_on_title"

  create_table "deposits", force: :cascade do |t|
    t.string   "agreement_version", limit: 255,                 null: false
    t.string   "uni",               limit: 255
    t.string   "name",              limit: 255,                 null: false
    t.string   "email",             limit: 255,                 null: false
    t.string   "file_path",         limit: 255,                 null: false
    t.text     "title",                                         null: false
    t.text     "authors",                                       null: false
    t.text     "abstract",                                      null: false
    t.string   "url",               limit: 255
    t.string   "doi_pmcid",         limit: 255
    t.text     "notes"
    t.boolean  "archived",                      default: false
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
  end

  create_table "email_preferences", force: :cascade do |t|
    t.string   "author",          limit: 255, null: false
    t.boolean  "monthly_opt_out"
    t.string   "email",           limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "email_preferences", ["author", "monthly_opt_out"], name: "index_email_preferences_on_author_and_monthly_opt_out"

  create_table "eventlogs", force: :cascade do |t|
    t.string   "event_name", limit: 255
    t.string   "user_name",  limit: 255
    t.string   "uid",        limit: 255
    t.string   "ip",         limit: 255
    t.string   "session_id", limit: 255
    t.datetime "timestamp"
  end

  create_table "logvalues", force: :cascade do |t|
    t.integer "eventlog_id"
    t.string  "param_name",  limit: 255
    t.string  "value",       limit: 255
  end

  create_table "reports", force: :cascade do |t|
    t.string   "name",         limit: 255, null: false
    t.string   "category",     limit: 255, null: false
    t.datetime "generated_on"
    t.integer  "user_id"
    t.text     "options"
    t.text     "data"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "reports", ["category"], name: "index_reports_on_category"

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "user_type",    limit: 255
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "statistics", force: :cascade do |t|
    t.string   "session_id", limit: 255
    t.string   "event",      limit: 255, null: false
    t.string   "ip_address", limit: 255
    t.string   "identifier", limit: 255
    t.string   "result",     limit: 255
    t.datetime "at_time",                null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "statistics", ["at_time"], name: "index_statistics_on_at_time"
  add_index "statistics", ["event"], name: "index_statistics_on_event"
  add_index "statistics", ["identifier"], name: "index_statistics_on_identifier"

  create_table "student_agreements", force: :cascade do |t|
    t.string   "uni",            limit: 255
    t.string   "name",           limit: 255
    t.string   "email",          limit: 255
    t.string   "years_embargo",  limit: 255
    t.string   "thesis_advisor", limit: 255
    t.string   "department",     limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type", limit: 255
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "users", force: :cascade do |t|
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.boolean  "admin"
    t.string   "login",                  limit: 255,             null: false
    t.string   "wind_login",             limit: 255
    t.string   "email",                  limit: 255
    t.string   "crypted_password",       limit: 255
    t.string   "persistence_token",      limit: 255
    t.integer  "login_count",                        default: 0, null: false
    t.text     "last_search_url"
    t.datetime "last_login_at"
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip",          limit: 255
    t.string   "current_login_ip",       limit: 255
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["last_request_at"], name: "index_users_on_last_request_at"
  add_index "users", ["login"], name: "index_users_on_login"
  add_index "users", ["persistence_token"], name: "index_users_on_persistence_token"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["wind_login"], name: "index_users_on_wind_login"

end
