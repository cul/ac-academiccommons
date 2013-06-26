class CreateEventlogs < ActiveRecord::Migration
  def self.up
    create_table :eventlogs do |t|
      t.integer    :id
      t.string     :event_name
      t.string     :user_name
      t.string     :uid
      t.string     :ip
      t.string     :session_id
      t.datetime   :timestamp 
    end  

  end

  def self.down
    drop_table :eventlogs
  end
end
