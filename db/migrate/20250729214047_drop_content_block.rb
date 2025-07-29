class DropContentBlock < ActiveRecord::Migration[6.0]
  def up
    drop_table :content_blocks
  end

  def down
    create_table :content_blocks do |t|
      t.string :title, null: false
      t.integer :user_id, null: false
      t.text :data
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :content_blocks, :title, name: "index_content_blocks_on_title"
  end
end
