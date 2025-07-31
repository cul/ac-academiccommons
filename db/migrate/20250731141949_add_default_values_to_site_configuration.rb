class AddDefaultValuesToSiteConfiguration < ActiveRecord::Migration[6.0]
  def change
    change_column_default :site_configurations, :downloads_enabled, from: nil, to: true
    change_column_default :site_configurations, :deposits_enabled, from: nil, to: true
    change_column_null :site_configurations, :downloads_enabled, false
    change_column_null :site_configurations, :deposits_enabled, false
    change_column_null :site_configurations, :singleton_guard, false
  end
end
