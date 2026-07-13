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
      StatisticsSummary
        .where(summary_month: result.months_processed)
        .find_in_batches(batch_size: BATCH_SIZE) do |batch|
          batch.each do |summary|
            verify_summary_row!(summary)
          end
        end
    end

    def verify_summary_row!(summary)
      expected = Statistic
                 .where(
                   identifier: summary.identifier,
                   event: summary.event,
                   at_time: summary_month_range(summary.summary_month)
                 )
                 .count

      return if expected == summary.count

      raise VerificationError,
            "Summary mismatch for #{summary.identifier}/#{summary.event}/#{summary.summary_month}: " \
            "expected #{expected}, found #{summary.count}"
    end

    def summary_month_range(month)
      month.beginning_of_month.beginning_of_day...
        month.next_month.beginning_of_month.beginning_of_day
    end
  end
end
