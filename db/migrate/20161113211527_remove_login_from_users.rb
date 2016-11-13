class RemoveLoginFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :login, :string
  end

  def down
    add_column :users, :login, :string
    add_index :users, :login
  end
end
