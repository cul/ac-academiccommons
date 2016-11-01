class AddProviderToUsers < ActiveRecord::Migration
  def change
    # Adding :provider for devise omniauth
    add_column :users, :provider, :string

    # Renaming :wind_login to :uid, which stores the user's uni.
    rename_column :users, :wind_login, :uid
  end
end
