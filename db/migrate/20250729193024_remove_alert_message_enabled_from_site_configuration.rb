class RemoveAlertMessageEnabledFromSiteConfiguration < ActiveRecord::Migration[6.0]
  def change
    remove_column :site_configurations, :alert_message_enabled, :boolean
  end
end
