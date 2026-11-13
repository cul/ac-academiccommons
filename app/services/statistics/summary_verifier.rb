# frozen_string_literal: true

module Statistics
  class SummaryVerifier
    class VerificationError < StandardError; end

    def self.run(result)
      new(result).run
    end

    def initialize(result)
      @result = result
    end

    def run
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

    # Both sides are keyed in Ruby with Statistic.summary_identifier, the same
    # normalization the rollup uses. Raw statistics are grouped by their exact
    # bytes (HEX) rather than with SQL string comparison, because MySQL
    # collations treat strings as equal that Ruby does not (case, trailing
    # spaces, zero-width characters, ...), which made the verifier and the
    # rollup disagree about which rows belong to which summary.
    def verify_month!(month, keys)
      expected_counts = expected_counts_for(month)
      summary_counts = summary_counts_for(month)

      keys.each do |identifier, event, _month|
        verify_key!(month, identifier, event, expected_counts, summary_counts)
      end
    end

    def expected_counts_for(month)
      Statistic
        .rollup_eligible
        .where(at_time: verification_range(month))
        .group(Arel.sql('HEX(identifier)'), Arel.sql('HEX(event)'))
        .count
        .each_with_object(Hash.new(0)) do |((identifier_hex, event_hex), count), totals|
          identifier = Statistic.summary_identifier(decode_hex(identifier_hex))
          totals[[identifier, decode_hex(event_hex)]] += count
        end
    end

    # Summed per normalized key so that summary rows written before the current
    # normalization (e.g. with a trailing space) are still accounted for.
    def summary_counts_for(month)
      StatisticsSummary
        .where(summary_month: month)
        .pluck(:identifier, :event, :count)
        .each_with_object(Hash.new(0)) do |(identifier, event, count), totals|
          totals[[Statistic.summary_identifier(identifier), event]] += count
        end
    end

    def verify_key!(month, identifier, event, expected_counts, summary_counts)
      key = [identifier, event]
      expected = expected_counts.fetch(key, 0)
      found = summary_counts.key?(key) ? summary_counts[key] : nil

      return if found == expected

      raise VerificationError,
            "Summary mismatch for #{identifier}/#{event}/#{month}: " \
            "expected #{expected}, found #{found.inspect}"
    end

    def decode_hex(hex)
      [hex].pack('H*').force_encoding(Encoding::UTF_8)
    end

    def statistics_in_window
      Statistic.where(at_time: result.from...result.before)
    end

    # The summaries for a month cover its events from the start of the month up
    # to this run's cutoff (result.before), not the whole month: the nightly
    # update stops a few minutes before "now", so events after the cutoff exist
    # but haven't been summarized yet.
    def verification_range(month)
      month_start = month.beginning_of_month.beginning_of_day
      month_end = month.next_month.beginning_of_month.beginning_of_day

      month_start...[month_end, result.before].min
    end
  end
end
