# frozen_string_literal: true

module Statistics
  class SummaryRollup
    BATCH_SIZE = 1_000

    def self.call(from:, to:)
      new(from: from, to: to).call
    end

    def initialize(from:, to:)
      @from = from
      @to = to
    end

    def call
      aggregates = aggregated_events
      rows_written = 0

      aggregates.each_slice(BATCH_SIZE) do |batch|
        rows_written += process_batch(batch)
      end

      months_processed = aggregates.keys.map(&:last).uniq.sort

      SummaryRollupResult.new(
        from: from,
        to: to,
        events_processed: aggregates.values.sum,
        summary_rows_written: rows_written,
        months_processed: months_processed
      )
    end

    private

    attr_reader :from, :to

    def aggregated_events
      @aggregated_events ||= begin
        totals = Hash.new(0)

        Statistic
          .where(at_time: from...to)
          .find_in_batches(batch_size: 10_000) do |batch|
            batch.each do |statistic|
              totals[
                [
                  statistic.identifier,
                  statistic.event,
                  statistic.at_time.beginning_of_month.to_date
                ]
              ] += 1
            end
          end

        totals
      end
    end

    def process_batch(batch)
      existing = existing_summaries(batch.map(&:first))

      summaries = batch.map do |(identifier, event, month), count|
        summary = existing[
          [identifier, event, month]
        ] || StatisticsSummary.new(
          identifier: identifier,
          event: event,
          summary_month: month,
          count: 0
        )

        summary.count += count

        summary
      end

      summaries.each(&:save!)

      summaries.size
    end

    def existing_summaries(keys)
      identifiers = keys.map(&:first).uniq
      events      = keys.map { |_, event, _| event }.uniq
      months      = keys.map(&:last).uniq

      StatisticsSummary
        .where(identifier: identifiers)
        .where(event: events)
        .where(summary_month: months)
        .index_by do |summary|
          [
            summary.identifier,
            summary.event,
            summary.summary_month
          ]
        end
    end
  end
end
