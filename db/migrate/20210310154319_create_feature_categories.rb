class CreateFeatureCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :feature_categories do |t|
      t.string :field_name, null: false
      t.string :label, null: false
      t.string :thumbnail_url, null: false
      t.float :threshold, default: 80.0
    end
    add_index :feature_categories, :field_name, unique: true
  end
end
