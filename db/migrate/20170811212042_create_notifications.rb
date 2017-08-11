class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :identifier, null: false
      t.string :type, null: false
      t.string :email
      t.string :uni
      t.datetime :sent_at
      t.boolean :success, null: false
      t.timestamps null: false
    end

    add_index :notifications, :identifier
  end
end
