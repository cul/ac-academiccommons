class RenameColumnsAndAddConstraintsToEmailPreferences < ActiveRecord::Migration[5.2]
  def change
    rename_column :email_preferences, :author, :uni
    rename_column :email_preferences, :monthly_opt_out, :unsubscribe
    
    add_index :email_preferences, :uni, unique: true
  end
end
