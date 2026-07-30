class AddAuthorizableAssociationToToken < ActiveRecord::Migration[7.1]
  def change
    add_column :tokens, :authorizable_id, :bigint, null: true
    add_column :tokens, :authorizable_type, :string
    add_column :tokens, :disabled, :datetime
    add_column :tokens, :created_at, :datetime
    add_column :tokens, :updated_at, :datetime
    add_index :tokens, [:authorizable_type, :authorizable_id], unique: true

    # At the time we define this association, all tokens are data feed tokens with a machine client,
    # so we create ApiClients for them.
    reversible do |direction|
      direction.up do
        Token.all.each do |token|
          next if token.authorizable
          api_client = APIClient.create(
            contact_email: token.contact_email, name: 'Datafeed API Client', description: token.description
          )
          token.authorizable = api_client
          token.save
        end
      end
      direction.down do
        Token.where(scope: Token::DATAFEED, authorizable_type: 'APIClient') do |token|
          token.authorizable.destroy!
        end
      end
    end

    change_column_null(:tokens, :authorizable_id, false)
  end
end
