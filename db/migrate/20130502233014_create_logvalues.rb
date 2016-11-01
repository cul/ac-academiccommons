class CreateLogvalues < ActiveRecord::Migration

  def self.up
    unless table_exists?("logvalues")
      create_table(:logvalues, { id: false }) do |t|
        t.integer    :id
        t.integer    :eventlog_id
        t.string     :param_name
        t.string     :value
      end
    end
  end

  def self.down
    drop_table :logvalues
  end
end
