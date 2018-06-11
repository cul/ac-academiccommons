class AddColumnsToDeposit < ActiveRecord::Migration[5.2]
  def change
    add_reference :deposits, :user, type: :integer, foreign_key: true

    add_column :deposits, :metadata, :text
    add_column :deposits, :hyacinth_identifier, :string
    add_column :deposits, :proxied, :boolean
    add_column :deposits, :authenticated, :boolean
  end
end
