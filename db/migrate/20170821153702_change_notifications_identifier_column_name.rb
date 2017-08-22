class ChangeNotificationsIdentifierColumnName < ActiveRecord::Migration
  def change
    rename_column :notifications, :identifier, :doi
  end
end
