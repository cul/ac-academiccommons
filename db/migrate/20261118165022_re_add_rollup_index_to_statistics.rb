class ReAddRollupIndexToStatistics < ActiveRecord::Migration[8.0]
  # Replaces 20260710000003_add_rollup_index_to_statistics, which was commented
  # out (due to server space issues) after it had already run as a no-op in
  # deployed environments, so re-enabling it there would have no effect.
  def change
    add_index :statistics,
              [:at_time, :event, :identifier],
              name: "index_statistics_rollup",
              if_not_exists: true
  end
end
