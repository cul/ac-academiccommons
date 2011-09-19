class CreateEmailPreferences < ActiveRecord::Migration
  def self.up
    create_table :email_preferences do |t|
      t.string :author, :null => false
      t.boolean :monthly_opt_out
      t.string :email
      t.timestamps
    end

    add_index :email_preferences, [:author, :monthly_opt_out]
  end

  def self.down
    drop_table :email_preferences
  end
end
