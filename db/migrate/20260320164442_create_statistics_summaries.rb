class CreateStatisticsSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :statistics_summaries do |t|
      t.string :identifier
      t.string :event
      t.integer :year
      t.integer :month
      t.integer :count

      t.timestamps
    end
  end
end
