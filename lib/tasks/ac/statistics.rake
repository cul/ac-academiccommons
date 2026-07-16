# frozen_string_literal: true

namespace :statistics do
  desc 'Update statistics summaries and prune old statistics'
  task update: :environment do
    started_at = Time.current

    from = parse_time(ENV['FROM'])
    to   = parse_time(ENV['TO'])

    abort 'FROM and TO must be supplied together' if from.present? != to.present?

    dry_run = ActiveModel::Type::Boolean.new.cast(
      ENV['DRY_RUN']
    )

    begin
      Rails.logger.info(
        {
          message: 'Statistics update started',
          from: from,
          to: to,
          dry_run: dry_run
        }.to_json
      )

      result = Statistics::Updater.call(
        from: from,
        to: to,
        dry_run: dry_run
      )

      Rails.logger.info(
        {
          message: 'Statistics update completed',
          events_processed: result.events_processed,
          summary_rows_written: result.summary_rows_written,
          months_processed: result.months_processed,
          dry_run: dry_run,
          duration_seconds: Time.current - started_at
        }.to_json
      )

      puts <<~OUTPUT
        Statistics update complete

        Events processed:     #{result.events_processed}
        Summary rows written: #{result.summary_rows_written}
        Months processed:     #{result.months_processed.join(', ')}
        Dry run:              #{dry_run}
        Duration:             #{(Time.current - started_at).round(2)} seconds
      OUTPUT
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

  desc 'Summarize and remove historical statistics for a specific time window'
  task backfill: :environment do
    from = parse_date(ENV['FROM'])
    to   = parse_date(ENV['TO'])

    unless from && to
      abort <<~MESSAGE
        FROM and TO are required.

        Example:
          rails statistics:backfill FROM=2016-01-01 TO=2017-01-01
      MESSAGE
    end

    abort 'FROM must be before TO' if from >= to

    dry_run = ActiveModel::Type::Boolean.new.cast(
      ENV['DRY_RUN']
    )

    puts "Summarizing statistics from #{from} to #{to}"

    result = Statistics::SummaryRollup.call(
      from: from.beginning_of_day,
      to: to.beginning_of_day
    )

    puts "Processed #{result.events_processed} events"
    puts "Updated #{result.summary_rows_written} summary rows"

    Statistics::SummaryVerifier.call(result)

    puts 'Verification passed'

    if dry_run
      puts 'DRY RUN: skipping deletion of statistics rows'
    else
      deleted = Statistics::Pruner.call(
        from: from.beginning_of_day,
        to: to.beginning_of_day
      )

      puts "Deleted #{deleted} statistics rows"
    end
  end

  private

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value)
  rescue ArgumentError
    abort "Invalid date/time value: #{value}"
  end

  def parse_date(value)
    return nil if value.blank?

    Date.parse(value)
  rescue ArgumentError
    abort "Invalid date: #{value}"
  end
end
