# frozen_string_literal: true

module Statistics
  class SummaryVerifier
    class VerificationError < StandardError; end

    BATCH_SIZE = 1_000

    def self.call(result)
      new(result).call
    end

    def initialize(result)
      @result = result
    end

    def call
      verify_processed_count!
      verify_skipped_count!
      verify_summary_rows!

      true
    end

    private

    attr_reader :result

    def verify_processed_count!
      actual = statistics_in_window
               .rollup_eligible
               .count

      return if actual == result.events_processed

      raise VerificationError,
            "Statistics count mismatch: expected #{actual}, " \
            "rollup processed #{result.events_processed}"
    end

    def verify_skipped_count!
      actual = statistics_in_window.count -
               statistics_in_window.rollup_eligible.count

      return if actual == result.skipped_statistics

      raise VerificationError,
            "Skipped statistics count mismatch: expected #{actual}, " \
            "rollup skipped #{result.skipped_statistics}"
    end

    def verify_summary_rows!
      result.touched_keys
            .group_by { |_identifier, _event, month| month }
            .each { |month, keys| verify_month!(month, keys) }
    end

    def verify_month!(month, keys)
      keys.each_slice(BATCH_SIZE) do |batch|
        verify_batch!(month, batch)
      end
    end

    def verify_batch!(month, batch)
      identifiers, events, = batch.transpose

      identifiers = identifiers.uniq
      events = events.uniq

      expected_counts = expected_counts_for(month, identifiers, events)
      summaries = summaries_for(month, identifiers, events)

      batch.each do |identifier, event, _month|
        verify_key!(month, identifier, event, expected_counts, summaries)
      end
    end

    def expected_counts_for(month, identifiers, events)
      Statistic
        .rollup_eligible
        .where(
          identifier: identifiers,
          event: events,
          at_time: summary_month_range(month)
        )
        .group(:identifier, :event)
        .count
    end

    def summaries_for(month, identifiers, events)
      StatisticsSummary
        .where(
          identifier: identifiers,
          event: events,
          summary_month: month
        )
        .index_by { |summary| [summary.identifier, summary.event] }
    end

    def verify_key!(month, identifier, event, expected_counts, summaries)
      expected = expected_counts[[identifier, event]] || 0
      summary = summaries[[identifier, event]]

      return if summary && expected == summary.count

      raise VerificationError,
            "Summary mismatch for #{identifier}/#{event}/#{month}: " \
            "expected #{expected}, found #{summary&.count.inspect}"
    end

    def statistics_in_window
      Statistic.where(at_time: result.from...result.to)
    end

    def summary_month_range(month)
      month.beginning_of_month.beginning_of_day...
        month.next_month.beginning_of_month.beginning_of_day
    end
  end
end
