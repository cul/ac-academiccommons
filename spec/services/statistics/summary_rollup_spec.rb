# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Statistics::SummaryRollup do
  def create_statistic(identifier:, event:, at_time:)
    Statistic.create!(
      identifier: identifier,
      event: event,
      at_time: at_time
    )
  end

  describe '.call' do
    let(:to) { Time.zone.parse('2026-08-01 00:00:00') }
    let(:checkpoint_time) { StatisticsSummaryCheckpoint.current.processed_until }

    it 'creates summary rows from statistics' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      result = described_class.call(to_date: to)
      summary = StatisticsSummary.find_by!(identifier: 'abc', event: 'download', summary_month: Date.new(2026, 7, 1))

      expect(summary.count).to eq(1)
      expect(result).to have_attributes(
        from: checkpoint_time,
        to: to,
        events_processed: 1,
        summary_rows_written: 1,
        months_processed: [Date.new(2026, 7, 1)]
      )
    end

    it 'groups multiple statistics into one summary count' do
      3.times do
        create_statistic(
          identifier: 'abc',
          event: 'download',
          at_time: Time.zone.parse('2026-07-10 12:00:00')
        )
      end

      described_class.call(to_date: to)

      summary = StatisticsSummary.find_by(
        identifier: 'abc',
        event: 'download'
      )

      expect(summary.count).to eq(3)
    end

    it 'keeps different identifiers separate' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      create_statistic(identifier: 'xyz', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      described_class.call(to_date: to)

      expect(StatisticsSummary.find_by(identifier: 'abc')&.count).to eq(1)
      expect(StatisticsSummary.find_by(identifier: 'xyz')&.count).to eq(1)
    end

    it 'keeps different events separate' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      create_statistic(identifier: 'abc', event: 'view', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      described_class.call(to_date: to)

      expect(StatisticsSummary.find_by(identifier: 'abc', event: 'download').count).to eq(1)
      expect(StatisticsSummary.find_by(identifier: 'abc', event: 'view').count).to eq(1)
    end

    it 'increments an existing summary count' do
      StatisticsSummary.create!(identifier: 'abc', event: 'download', summary_month: Date.new(2026, 7, 1), count: 10)

      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      described_class.call(to_date: to)

      summary = StatisticsSummary.find_by(identifier: 'abc', event: 'download')

      expect(summary.count).to eq(11)
    end

    it 'does not include statistics outside the requested range' do
      create_statistic(
        identifier: 'abc',
        event: 'download',
        at_time: checkpoint_time - 1.day
      )

      create_statistic(
        identifier: 'abc',
        event: 'download',
        at_time: to + 1.day
      )

      described_class.call(to_date: to)

      expect(StatisticsSummary.count).to eq(0)
    end

    it 'puts events into the correct summary month' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-31 23:59:59'))
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-08-01 00:00:00'))

      described_class.call(
        to_date: Time.zone.parse('2026-09-01 00:00:00')
      )

      expect(StatisticsSummary.find_by(summary_month: Date.new(2026, 7, 1)).count).to eq(1)
      expect(StatisticsSummary.find_by(summary_month: Date.new(2026, 8, 1)).count).to eq(1)
    end

    it 'handles more than one batch of aggregated events' do
      stub_const('Statistics::SummaryRollup::BATCH_SIZE', 2)

      3.times do |index|
        create_statistic(
          identifier: "id-#{index}",
          event: 'download',
          at_time: Time.zone.parse('2026-07-10 12:00:00')
        )
      end

      described_class.call(to_date: to)

      expect(StatisticsSummary.count).to eq(3)
    end

    it 'skips statistics that are not rollup eligible' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-31 23:59:59'))
      create_statistic(identifier: 'xyz', event: '', at_time: Time.zone.parse('2026-08-01 00:00:00'))

      result = described_class.call(to_date: Date.parse('2026-08-05'))

      expect(result.events_processed).to eq(1)
      expect(result.skipped_statistics).to eq(1)

      expect(StatisticsSummary.count).to eq(1)
    end

    it 'logs skipped statistics' do
      create_statistic(identifier: '', event: 'view', at_time: Time.zone.parse('2026-08-01 00:00:00'))

      expect(Rails.logger)
        .to receive(:warn)
        .with(/Skipping Statistic/)

      described_class.call(to_date: Date.parse('2026-08-05'))
    end

    it 'does not create summaries for invalid statistics' do
      create_statistic(identifier: '', event: 'view', at_time: Time.zone.parse('2026-08-01 00:00:00'))

      described_class.call(to_date: Date.parse('2026-08-05'))

      expect(StatisticsSummary.count).to eq(0)
    end

    it 'reports zero skipped statistics when all records are valid' do
      create_statistic(identifier: 'xyz', event: 'view', at_time: Time.zone.parse('2026-08-01 00:00:00'))

      result = described_class.call(to_date: Date.parse('2026-08-05'))

      expect(result.skipped_statistics).to eq(0)
    end
  end
end
