# frozen_string_literal: true

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
    to_date = parse_date(ENV['TO'])

    unless to_date
      abort <<~MESSAGE
        TO is required.

        Example:
          rails statistics:backfill TO=2017-01-01
      MESSAGE
    end

    puts "Summarizing statistics to #{to_date}"

    result = Statistics::Updater.call(
      to_date: to_date.beginning_of_day
    )

    puts "Processed #{result.events_processed} events"
    puts "Updated #{result.summary_rows_written} summary rows"
  end

  desc 'Prune up to a certain date before checkpoint'
  task prune: :environment do
    to_date = parse_date(ENV['TO'])

    unless to_date
      abort <<~MESSAGE
        TO is required.

        Example:
          rails statistics:prune TO=2017-01-01
      MESSAGE
    end

    puts "Pruning statistics to #{to_date}"

    num_deleted = Statistics::Pruner.call(
      to_date: to_date.beginning_of_day
    )

    puts "Removed #{num_deleted} events"
  end

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value)
  rescue ArgumentError
    abort "Invalid date: #{value}"
  end
end
