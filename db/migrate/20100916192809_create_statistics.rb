class CreateStatistics < ActiveRecord::Migration
  def self.up
    create_table :statistics do |t|
      t.string :session_id
      t.string :event, :null => false
      t.string :ip_address
      t.string :identifier
      t.string :result
      t.datetime :at_time, :null => false
      t.timestamps
    end

    add_index :statistics, :event
    add_index :statistics, :identifier
    add_index :statistics, :at_time
  end

  def self.down
    drop_table :statistics
  end
end
