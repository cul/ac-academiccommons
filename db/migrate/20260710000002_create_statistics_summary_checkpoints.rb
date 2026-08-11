class CreateStatisticsSummaryCheckpoints < ActiveRecord::Migration[8.0]
  class StatisticsSummaryCheckpoint < ActiveRecord::Base
    self.table_name = "statistics_summary_checkpoints"
  end

  def up
    create_table :statistics_summary_checkpoints do |t|
      t.datetime :processed_until, null: false

      t.timestamps
    end

    checkpoint_time = Time.at(0).utc

    StatisticsSummaryCheckpoint.create!(
      id: 1,
      processed_until: checkpoint_time,
      created_at: checkpoint_time,
      updated_at: checkpoint_time
    )
  end

  def down
    drop_table :statistics_summary_checkpoints
  end
end
