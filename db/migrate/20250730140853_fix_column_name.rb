class FixColumnName < ActiveRecord::Migration[6.0]
  def self.up
    rename_column :site_configurations, :singleton_gaurd , :singleton_guard
  end

  def self.down
    rename_column :site_configurations, :singleton_guard, :singleton_gaurd 
  end
end
