class InitSchema < ActiveRecord::Migration
  def up
    create_table "agreements", force: :cascade do |t|
      t.string   "uni"
      t.string   "name"
      t.string   "email"
      t.string   "agreement_version"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    create_table "bookmarks", force: :cascade do |t|
      t.integer  "user_id",     null: false
      t.string   "document_id"
      t.string   "title"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "user_type"
    end
    create_table "content_blocks", force: :cascade do |t|
      t.string   "title",      null: false
      t.integer  "user_id",    null: false
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "content_blocks", ["title"], name: "index_content_blocks_on_title"
    create_table "deposits", force: :cascade do |t|
      t.string   "agreement_version",                 null: false
      t.string   "uni"
      t.string   "name",                              null: false
      t.string   "email",                             null: false
      t.string   "file_path",                         null: false
      t.text     "title",                             null: false
      t.text     "authors",                           null: false
      t.text     "abstract",                          null: false
      t.string   "url"
      t.string   "doi_pmcid"
      t.text     "notes"
      t.boolean  "archived",          default: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    create_table "email_preferences", force: :cascade do |t|
      t.string   "author",          null: false
      t.boolean  "monthly_opt_out"
      t.string   "email"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "email_preferences", ["author", "monthly_opt_out"], name: "index_email_preferences_on_author_and_monthly_opt_out"
    create_table "eventlogs", id: false, force: :cascade do |t|
      t.integer  "id"
      t.string   "event_name"
      t.string   "user_name"
      t.string   "uid"
      t.string   "ip"
      t.string   "session_id"
      t.datetime "timestamp"
    end
    create_table "logvalues", id: false, force: :cascade do |t|
      t.integer "id"
      t.integer "eventlog_id"
      t.string  "param_name"
      t.string  "value"
    end
    create_table "notifications", force: :cascade do |t|
      t.string   "doi",        null: false
      t.string   "kind",       null: false
      t.string   "email"
      t.string   "uni"
      t.datetime "sent_at"
      t.boolean  "success",    null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    add_index "notifications", ["doi"], name: "index_notifications_on_doi"
    create_table "searches", force: :cascade do |t|
      t.text     "query_params"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "user_type"
    end
    add_index "searches", ["user_id"], name: "index_searches_on_user_id"
    create_table "sessions", force: :cascade do |t|
      t.string   "session_id", null: false
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
    add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"
    create_table "statistics", force: :cascade do |t|
      t.string   "session_id"
      t.string   "event",      null: false
      t.string   "ip_address"
      t.string   "identifier"
      t.string   "result"
      t.datetime "at_time",    null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "statistics", ["at_time"], name: "index_statistics_on_at_time"
    add_index "statistics", ["event"], name: "index_statistics_on_event"
    add_index "statistics", ["identifier"], name: "index_statistics_on_identifier"
    create_table "taggings", force: :cascade do |t|
      t.integer  "tag_id"
      t.integer  "taggable_id"
      t.string   "taggable_type"
      t.datetime "created_at"
    end
    add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id"
    add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type"
    create_table "tags", force: :cascade do |t|
      t.string "name"
    end
    create_table "users", force: :cascade do |t|
      t.string   "first_name"
      t.string   "last_name"
      t.boolean  "admin"
      t.string   "uid",                                null: false
      t.string   "email"
      t.string   "crypted_password"
      t.string   "persistence_token"
      t.integer  "sign_in_count",          default: 0, null: false
      t.text     "last_search_url"
      t.datetime "last_sign_in_at"
      t.datetime "last_request_at"
      t.datetime "current_sign_in_at"
      t.string   "last_sign_in_ip"
      t.string   "current_sign_in_ip"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.string   "provider"
    end
    add_index "users", ["email"], name: "index_users_on_email", unique: true
    add_index "users", ["last_request_at"], name: "index_users_on_last_request_at"
    add_index "users", ["persistence_token"], name: "index_users_on_persistence_token"
    add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    add_index "users", ["uid"], name: "index_users_on_uid"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end
