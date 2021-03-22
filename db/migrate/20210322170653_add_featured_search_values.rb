class AddFeaturedSearchValues < ActiveRecord::Migration[5.2]
  def change
    create_table :featured_search_values do |t|
      t.string :value, null: false, index: true
    end
    add_reference :featured_search_values, :featured_search, foreign_key: true, null: false
    rename_column :featured_searches, :filter_value, :label
  end
end
