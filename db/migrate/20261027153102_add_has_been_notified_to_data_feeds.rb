class AddHasBeenNotifiedToDataFeeds < ActiveRecord::Migration[8.0]
  def change
    add_column :data_feeds, :has_been_notified, :boolean, default: false
  end
end
