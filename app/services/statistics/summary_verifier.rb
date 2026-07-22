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
      verify_total_count!
      verify_summary_rows!

      true
    end

    private

    attr_reader :result

    def verify_total_count!
      actual = Statistic
               .where(at_time: result.from...result.to)
               .count

      return if actual == result.events_processed

      raise VerificationError,
            "Statistics count mismatch: expected #{actual}, " \
            "rollup processed #{result.events_processed}"
    end

    def verify_summary_rows!
      result.touched_keys
            .group_by { |_identifier, _event, month| month }
            .each { |month, keys| verify_month!(month, keys) }
    end

    def verify_month!(month, keys)
      keys.each_slice(BATCH_SIZE) { |batch| verify_batch!(month, batch) }
    end

    def verify_batch!(month, batch)
      identifiers, events, = batch.transpose

      expected_counts = Statistic
                        .where(identifier: identifiers.uniq, event: events.uniq, at_time: summary_month_range(month))
                        .group(:identifier, :event)
                        .count

      summaries = StatisticsSummary
                  .where(identifier: identifiers.uniq, event: events.uniq, summary_month: month)
                  .index_by { |s| [s.identifier, s.event] }

      batch.each { |identifier, event, _month| verify_key!(month, identifier, event, expected_counts, summaries) }
    end

    def verify_key!(month, identifier, event, expected_counts, summaries)
      expected = expected_counts[[identifier, event]] || 0
      summary = summaries[[identifier, event]]

      return if summary && expected == summary.count

      raise VerificationError, "Summary mismatch for #{identifier}/#{event}/#{month}: " \
            "expected #{expected}, found #{summary&.count.inspect}"
    end

    def summary_month_range(month)
      (month.beginning_of_month.beginning_of_day...
        month.next_month.beginning_of_month.beginning_of_day)
    end
  end
end
