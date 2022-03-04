class CreateFeaturedSearches < ActiveRecord::Migration[5.2]
  def change
    create_table :featured_searches do |t|
      t.string :slug, null: false
      t.string :filter_value, null: false, index: true
      t.integer :priority, null: false, default: 0
      t.string :url
      t.string :thumbnail_url
      t.text :description
    end
    add_reference :featured_searches, :feature_category, foreign_key: true, null: false
    add_index :featured_searches, :slug, unique: true
  end
end
