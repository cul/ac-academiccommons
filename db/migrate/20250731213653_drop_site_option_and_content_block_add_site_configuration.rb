class DropSiteOptionAndContentBlockAddSiteConfiguration < ActiveRecord::Migration[6.0]
  def change
    # 1) Create the new site_configurations table
    create_table :site_configurations do |t|
      t.boolean :downloads_enabled,  default: true,  null: false
      t.string  :downloads_message
      t.boolean :deposits_enabled,   default: true,  null: false
      t.string  :alert_message
      t.integer :singleton_guard,     null: false

      t.timestamps
    end
    add_index :site_configurations, :singleton_guard, unique: true

    # 2) Drop site_options (but define its columns so Rails can roll it back)
    drop_table :site_options do |t|
      t.string  :name
      t.boolean :value
    end

    # 3) Drop content_blocks (again defining columns + index for rollback)
    drop_table :content_blocks do |t|
      t.string   :title,      null: false
      t.integer  :user_id,    null: false
      t.text     :data
      t.datetime :created_at
      t.datetime :updated_at

      t.index :title, name: "index_content_blocks_on_title"
    end
  end
end