class CreateAgreements < ActiveRecord::Migration
  def change
    create_table :agreements do |t|
      t.string :uni
      t.string :name
      t.string :email
      t.string :agreement_version

      t.timestamps
    end
  end
end
