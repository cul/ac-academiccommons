# frozen_string_literal: true

namespace :ac do
  namespace :statistics do
    desc "For cron; to update yesterday's statistics summaries and prune statistics older than one year"
    task nightly_update: :environment do
      started_at = Time.current

      begin
        Rails.logger.info(
          {
            message: 'Statistics update started'
          }.to_json
        )

        result = Statistics::Updater.call

        Rails.logger.info(
          {
            message: 'Statistics update completed',
            events_processed: result.events_processed,
            summary_rows_written: result.summary_rows_written,
            months_processed: result.months_processed,
            duration_seconds: Time.current - started_at
          }.to_json
        )

        deleted = Statistics::Pruner.call

        Rails.logger.info("Deleted #{deleted} statistics rows")
      rescue StandardError => e
        Rails.logger.error(
          {
            message: 'Statistics update failed',
            error: e.class.name,
            detail: e.message,
            backtrace: e.backtrace.first(10)
          }.to_json
        )

        raise
      end
    end

    desc 'Summarize historical statistics for a specific time window'
    task backfill: :environment do
      to_date = parse_year_month(ENV['TO'])

      unless to_date
        abort <<~MESSAGE
          TO is required and must be in YYYY-MM format.

          TO is the exclusive end of the range: events from that month
          onward are excluded and will be picked up by a later run.

          Example:
            rails ac:statistics:backfill TO=2017-01
        MESSAGE
      end

      puts "Summarizing statistics up to (not including) #{to_date}"

      result = Statistics::Updater.call(to_date: to_date.beginning_of_day)

      puts "Processed #{result.events_processed} events"
      puts "Updated #{result.summary_rows_written} summary rows"
    end

    desc 'Prune up to a certain date before checkpoint'
    task prune: :environment do
      to_date = parse_year_month(ENV['TO'])

      unless to_date
        abort <<~MESSAGE
          TO is required and must be in YYYY-MM format.

          TO is the exclusive end of the range: statistics from that month
          onward are kept, not pruned.

          Example:
            rails ac:statistics:prune TO=2017-01
        MESSAGE
      end

      puts "Pruning statistics up to (not including) #{to_date}"

      num_deleted = Statistics::Pruner.call(to_date: to_date.beginning_of_day)

      puts "Removed #{num_deleted} events"
    end

    def parse_year_month(value)
      return nil if value.blank?

      unless /\A\d{4}-(0[1-9]|1[0-2])\z/.match?(value)
        abort "Invalid value: #{value.inspect}. TO must be in YYYY-MM format (e.g. 2014-01)."
      end

      Date.strptime(value, '%Y-%m')
    rescue ArgumentError
      abort "Invalid date: #{value}"
    end
  end
end
