class CreateSiteOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :site_options do |t|
      t.string :name
      t.boolean :value
    end
  end
end
