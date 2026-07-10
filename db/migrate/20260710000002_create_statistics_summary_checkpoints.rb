class CreateStatisticsSummaryCheckpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :statistics_summary_checkpoints do |t|
      t.datetime :processed_until, null: false

      t.timestamps
    end
  end
end