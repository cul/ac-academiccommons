class AddRollupIndexToStatistics < ActiveRecord::Migration[8.0]
  # Intentionally a no-op: this index was removed due to server space issues
  # after this migration had already run in deployed environments.
  # Superseded by 20261118165022_re_add_rollup_index_to_statistics.
  def change
  end
end
