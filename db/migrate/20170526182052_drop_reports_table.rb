class DropReportsTable < ActiveRecord::Migration
  def up
    drop_table :reports
  end

  def down
    create_table :reports do |t|
      t.string :name,     :null => false
      t.string :category, :null => false
      t.datetime :generated_on
      t.integer :user_id
      t.text :options
      t.text :data

      t.timestamps
    end
    add_index :reports, :category
  end
end
