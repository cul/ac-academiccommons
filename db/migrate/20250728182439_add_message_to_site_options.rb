class AddMessageToSiteOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :site_options, :message, :string
  end
end
