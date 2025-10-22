class CreateAPIClients < ActiveRecord::Migration[7.1]
  def change
    create_table :api_clients do |t|
      t.string :name
      t.string :contact_email
      t.text :description
      t.datetime :created_at
      t.datetime :updated_at
    end
    Token.all do |token|
      next if token.authorizable
      api_client = APIClient.create(
        contact_email: token.contact_email, name: 'Datafeed API Client', description: token.description
      )
      token.authorizable = api_client
      token.save
    end
  end
end
