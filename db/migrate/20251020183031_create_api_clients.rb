class CreateAPIClients < ActiveRecord::Migration[7.1]
  def change
    create_table :api_clients do |t|
      t.string :name
      t.string :contact_email
      t.text :description
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
