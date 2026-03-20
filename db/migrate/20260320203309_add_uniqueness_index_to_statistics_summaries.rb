class AddUniquenessIndexToStatisticsSummaries < ActiveRecord::Migration[7.0]
  def change
    add_index :statistics_summaries,
              [:identifier, :event, :year, :month],
              unique: true,
              name: "index_statistics_summaries_on_identifier_event_year_month"
  end
end