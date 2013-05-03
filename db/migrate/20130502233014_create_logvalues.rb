class CreateLogvalues < ActiveRecord::Migration

  def self.up
    create_table :logvalues do |t|
      t.integer    :id
      t.integer    :eventlog_id
      t.string     :param_name
      t.string     :value
    end  

  end

  def self.down
    drop_table :logvalues
  end
end