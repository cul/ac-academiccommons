class ChangeColumnName < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :crypted_password, :encrypted_password
  end
end
