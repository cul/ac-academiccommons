# frozen_string_literal: true

module Statistics
  class SummaryRollup
    BATCH_SIZE = 1_000

    def self.run(before_date:)
      new(before_date: before_date).run
    end

    def initialize(before_date:)
      @before_date = before_date
    end

    def run
      aggregates = aggregated_events
      rows_written = 0

      aggregates.each_slice(BATCH_SIZE) do |batch|
        rows_written += process_batch(batch)
      end

      build_result(aggregates, rows_written)
    end

    private

    attr_reader :before_date

    def aggregated_events
      @aggregated_events ||= begin
        totals = Hash.new(0)
        @skipped_statistics = 0

        Statistic
          .where(at_time: checkpoint.processed_until...before_date)
          .find_in_batches(batch_size: 10_000) do |batch|
            aggregate_batch(batch, totals)
          end

        totals
      end
    end

    def aggregate_batch(batch, totals)
      batch.each do |stat|
        next unless processable?(stat)

        totals[event_key(stat)] += 1
      end
    end

    def event_key(statistic)
      [
        Statistic.summary_identifier(statistic.identifier),
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
        before: before_date,
        events_processed: aggregates.values.sum,
        summary_rows_written: rows_written,
        months_processed: aggregates.keys.map(&:last).uniq.sort,
        touched_keys: aggregates.keys,
        skipped_statistics: @skipped_statistics
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
        .index_by { |s| [Statistic.summary_identifier(s.identifier), s.event, s.summary_month] }
    end

    def checkpoint
      @checkpoint ||= StatisticsSummaryCheckpoint.current
    end

    def processable?(stat)
      return true if stat.rollup_eligible?

      @skipped_statistics += 1
      log_skipped(stat)
      false
    end

    def log_skipped(stat)
      Rails.logger.warn(
        "Skipping Statistic #{stat.id}: " \
        "identifier=#{stat.identifier.inspect}, " \
        "event=#{stat.event.inspect}, " \
        "at_time=#{stat.at_time.inspect}"
      )
    end
  end
end
