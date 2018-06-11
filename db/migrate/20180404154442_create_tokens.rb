class CreateTokens < ActiveRecord::Migration[4.2]
  def change
    create_table :tokens do |t|
      t.string :token, null: false
      t.string :scope, null: false
      t.string :contact_email
      t.text :description
    end

    add_index :tokens, :token, unique: true
    add_index :tokens, :scope
    add_index :tokens, [:scope, :token]
  end
end
