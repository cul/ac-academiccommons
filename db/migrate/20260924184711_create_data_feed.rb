class CreateDataFeed < ActiveRecord::Migration[8.0]
  def change
    create_table :data_feeds do |t|
      t.timestamps
      t.string :key, null: false
      t.text :search_fields, default: '{}', null: false

      t.index :key, unique: true
    end
  end
end
