class AddAuthorizableAssociationToToken < ActiveRecord::Migration[7.1]
  def change
    add_column :tokens, :authorizable_id, :bigint, null: false
    add_column :tokens, :authorizable_type, :string
    add_column :tokens, :disabled, :datetime
    add_column :tokens, :created_at, :datetime
    add_column :tokens, :updated_at, :datetime
    add_index :tokens, [:authorizable_type, :authorizable_id], unique: true
  end
end
