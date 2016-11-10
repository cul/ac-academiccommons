class AddDeviseToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      ## Database authenticatable
      # t.string :email,              null: false, default: ""
      # t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      ## Renaming old columns to match the column names Devise expects.
      t.rename :login_count,      :sign_in_count
      t.rename :current_login_at, :current_sign_in_at
      t.rename :last_login_at,    :last_sign_in_at
      t.rename :current_login_ip, :current_sign_in_ip
      t.rename :last_login_ip,    :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at


      # Uncomment below if timestamps were not included in your original model.
      # t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end

  def self.down
    change_table :users do |t|
      t.remove :reset_password_token, :reset_password_sent_at,
        :remember_created_at

      t.rename :sign_in_count, :login_count
      t.rename :current_sign_in_at, :current_login_at
      t.rename :last_sign_in_at, :last_login_at
      t.rename :current_sign_in_ip, :current_login_ip
      t.rename :last_sign_in_ip, :last_login_ip
    end

    remove_index :users, :email
  end
end
