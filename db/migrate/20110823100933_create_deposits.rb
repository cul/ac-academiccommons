class CreateDeposits < ActiveRecord::Migration
  def self.up
    create_table :deposits do |t|
      t.string :agreement_version, :null => false
      t.string :uni, :null => false
      t.string :name, :null => false
      t.string :email, :null => false
      t.string :file_path, :null => false
      t.text :title, :null => false
      t.text :authors, :null => false
      t.text :abstract, :null => false
      t.string :url
      t.string :doi_pmcid
      t.text :notes
      t.boolean :archived, :default => false
      t.timestamps
    end

    add_index :deposits, [:uni, :name, :email]
  end

  def self.down
    drop_table :deposits
  end
end
