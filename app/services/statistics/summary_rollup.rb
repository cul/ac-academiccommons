# frozen_string_literal: true

module Statistics
  class SummaryRollup
    BATCH_SIZE = 1_000

    def self.call(to_date:)
      new(to_date: to_date).call
    end

    def initialize(to_date:)
      @to_date = to_date
    end

    def call
      aggregates = aggregated_events
      rows_written = 0

      aggregates.each_slice(BATCH_SIZE) do |batch|
        rows_written += process_batch(batch)
      end

      build_result(aggregates, rows_written)
    end

    private

    attr_reader :to_date

    def aggregated_events
      @aggregated_events ||= begin
        totals = Hash.new(0)

        Statistic.where(at_time: checkpoint.processed_until...to_date).find_in_batches(batch_size: 10_000) do |batch|
          batch.each { |stat| totals[event_key(stat)] += 1 }
        end

        totals
      end
    end

    def event_key(statistic)
      [
        statistic.identifier,
        statistic.event,
        statistic.at_time.beginning_of_month.to_date
      ]
    end

    def process_batch(batch)
      existing = existing_summaries(batch.map(&:first))

      summaries = batch.map do |key, count|
        find_or_initialize_summary(existing, key).tap { |summary| summary.count += count }
      end

      summaries.each(&:save!).size
    end

    def build_result(aggregates, rows_written)
      SummaryRollupResult.new(
        from: checkpoint.processed_until,
        to: to_date,
        events_processed: aggregates.values.sum,
        summary_rows_written: rows_written,
        months_processed: aggregates.keys.map(&:last).uniq.sort,
        touched_keys: aggregates.keys
      )
    end

    def find_or_initialize_summary(existing, key)
      identifier, event, month = key

      existing[key] || StatisticsSummary.new(
        identifier: identifier,
        event: event,
        summary_month: month,
        count: 0
      )
    end

    def existing_summaries(keys)
      identifiers, events, months = keys.transpose.map(&:uniq)

      StatisticsSummary
        .where(identifier: identifiers, event: events, summary_month: months)
        .index_by { |s| [s.identifier, s.event, s.summary_month] }
    end

    def checkpoint
      @checkpoint ||= StatisticsSummaryCheckpoint.current
    end
  end
end
