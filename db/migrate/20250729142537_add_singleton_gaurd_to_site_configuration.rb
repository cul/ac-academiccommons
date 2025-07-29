class AddSingletonGaurdToSiteConfiguration < ActiveRecord::Migration[6.0]
  def change
    add_column :site_configurations, :singleton_gaurd, :integer
  end
end
