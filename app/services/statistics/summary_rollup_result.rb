# frozen_string_literal: true

module Statistics
  SummaryRollupResult = Data.define(
    :from,
    :to,
    :events_processed,
    :summary_rows_written,
    :months_processed,
    :touched_keys,
    :skipped_statistics
  )
end
