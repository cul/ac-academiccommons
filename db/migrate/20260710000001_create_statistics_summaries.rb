class CreateStatisticsSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :statistics_summaries do |t|
      t.string :identifier,    null: false
      t.string :event,         null: false
      t.date   :summary_month, null: false

      t.bigint :count, null: false, default: 0

      t.timestamps
    end

    add_index :statistics_summaries,
              [:identifier, :event, :summary_month],
              unique: true,
              name: "index_statistics_summaries_unique"

    add_index :statistics_summaries,
              [:event, :summary_month],
              name: "index_statistics_summaries_event_month"

    add_index :statistics_summaries, :identifier
  end
end