class AddUniqIndexToSiteConfiguration < ActiveRecord::Migration[6.0]
  def change
     change_table :site_configurations do |t|
       t.index :singelton_guard, unique: true
     end
  end
end
