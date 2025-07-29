class DropSiteOptions < ActiveRecord::Migration[6.0]
  def change
    drop_table :site_options do |t|
      t.string :name
      t.boolean :value
      t.string :message
    end
  end
end
