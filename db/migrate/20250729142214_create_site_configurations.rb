class CreateSiteConfigurations < ActiveRecord::Migration[6.0]
  def change
    create_table :site_configurations do |t|
      t.boolean :downloads_enabled
      t.string :downloads_message
      t.boolean :deposits_enabled
      t.boolean :alert_message_enabled
      t.string :alert_message

      t.timestamps
    end
  end
end
