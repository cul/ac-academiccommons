class CreateEventlogs < ActiveRecord::Migration
  def self.up
    unless table_exists?("eventlogs")
      create_table(:eventlogs, { id: false }) do |t|
        t.integer    :id
        t.string     :event_name
        t.string     :user_name
        t.string     :uid
        t.string     :ip
        t.string     :session_id
        t.datetime   :timestamp
      end
    end
  end

  def self.down
    drop_table :eventlogs
  end
end
