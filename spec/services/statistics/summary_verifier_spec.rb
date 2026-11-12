# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Statistics::SummaryVerifier do
  let(:to) { Time.zone.parse('2026-08-01 00:00:00') }

  def create_statistic(identifier:, event:, at_time:)
    Statistic.create!(
      identifier: identifier,
      event: event,
      at_time: at_time
    )
  end

  def rollup_result
    Statistics::SummaryRollup.run(
      before_date: to
    )
  end

  describe '.run' do
    it 'passes when summaries match statistics' do
      create_statistic(
        identifier: 'abc',
        event: 'download',
        at_time: Time.zone.parse('2026-07-10 12:00:00')
      )

      result = rollup_result

      expect(
        described_class.run(result)
      ).to eq(true)
    end

    it 'passes when identifiers differ only by case or surrounding spaces' do
      ['abc', 'ABC ', ' abc'].each do |identifier|
        create_statistic(identifier: identifier, event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      end

      expect(described_class.run(rollup_result)).to eq(true)
    end

    it 'passes when identifiers differ only by invisible characters' do
      ["abc\u200B", "a\u00ADbc", 'abc'].each do |identifier|
        create_statistic(identifier: identifier, event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      end

      expect(described_class.run(rollup_result)).to eq(true)
    end

    it 'counts rows with invisible characters toward the normalized identifier' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      create_statistic(identifier: "abc\u200B", event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      result = rollup_result
      StatisticsSummary.find_by!(identifier: 'abc').update!(count: 1)

      expect {
        described_class.run(result)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError,
        %r{abc/download/2026-07-01: expected 2, found 1}
      )
    end

    it 'passes when identifiers differ only by compatibility characters' do
      ['10.7916/D8...', '10.7916/D8…'].each do |identifier|
        create_statistic(identifier: identifier, event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      end

      expect(described_class.run(rollup_result)).to eq(true)
      expect(StatisticsSummary.pluck(:identifier, :count)).to eq([['10.7916/d8...', 2]])
    end

    it 'handles non-ASCII identifiers' do
      create_statistic(identifier: 'Café', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      expect(described_class.run(rollup_result)).to eq(true)
      expect(StatisticsSummary.pluck(:identifier)).to eq(['café'])
    end

    it 'includes legacy summary rows whose identifier is not normalized' do
      StatisticsSummary.create!(identifier: 'abc ', event: 'download', summary_month: Date.new(2026, 7, 1), count: 1)
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-01 12:00:00'))
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      StatisticsSummaryCheckpoint.current.update!(processed_until: Time.zone.parse('2026-07-05 00:00:00'))

      expect(described_class.run(rollup_result)).to eq(true)
    end

    it 'raises when the raw statistic count does not match the rollup result' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      altered_result = rollup_result.with(events_processed: 99)

      expect {
        described_class.run(altered_result)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError,
        /Statistics count mismatch/
      )
    end

    it 'raises when a summary count does not match statistics' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      result = rollup_result

      summary = StatisticsSummary.find_by!(identifier: 'abc', event: 'download')

      summary.update!(
        count: 50
      )

      expect {
        described_class.run(result)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError,
        /Summary mismatch/
      )
    end

    it 'checks different identifiers separately' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      create_statistic(identifier: 'xyz', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      result = rollup_result

      summary = StatisticsSummary.find_by!(
        identifier: 'xyz'
      )

      summary.update!(
        count: 10
      )

      expect {
        described_class.run(result)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError
      )
    end

    it 'checks different events separately' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      create_statistic(identifier: 'abc', event: 'view', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      result = rollup_result

      summary = StatisticsSummary.find_by!(
        event: 'view'
      )

      summary.update!(
        count: 20
      )

      expect {
        described_class.run(result)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError
      )
    end

    it 'raises when a touched summary row is missing entirely' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      result = rollup_result

      StatisticsSummary.find_by!(identifier: 'abc', event: 'download').destroy!

      expect {
        described_class.run(result)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError,
        /Summary mismatch/
      )
    end

    it 'does not re-verify summary rows outside this run\'s touched keys' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-05 12:00:00'))
      first_to = Time.zone.parse('2026-07-06 00:00:00')
      Statistics::SummaryRollup.run(before_date: first_to)

      StatisticsSummaryCheckpoint.current.update!(processed_until: first_to)

      StatisticsSummary.find_by!(identifier: 'abc', event: 'download').update!(count: 999)

      create_statistic(identifier: 'xyz', event: 'download', at_time: Time.zone.parse('2026-07-20 12:00:00'))
      second_result = Statistics::SummaryRollup.run(before_date: to)

      expect(second_result.touched_keys.map(&:first)).to eq(['xyz'])
      expect(described_class.run(second_result)).to eq(true)
    end

    it 'raises when the skipped statistic count does not match the rollup result' do
      create_statistic(
        identifier: nil,
        event: 'download',
        at_time: Time.zone.parse('2026-07-10 12:00:00')
      )

      result = rollup_result

      altered_result = result.with(skipped_statistics: 99)

      expect {
        described_class.run(altered_result)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError,
        /Skipped statistics count mismatch/
      )
    end

    it 'does not include skipped statistics in the processed count verification' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))
      create_statistic(identifier: nil, event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      result = rollup_result

      expect(result.events_processed).to eq(1)
      expect(result.skipped_statistics).to eq(1)

      expect(
        described_class.run(result)
      ).to eq(true)
    end

    it 'does not expect summary rows for skipped statistics' do
      create_statistic(
        identifier: nil,
        event: 'download',
        at_time: Time.zone.parse('2026-07-10 12:00:00')
      )

      result = rollup_result

      expect(StatisticsSummary.count).to eq(0)

      expect(
        described_class.run(result)
      ).to eq(true)
    end

    it 'there are zero skipped statistics when summaries match statistics' do
      create_statistic(
        identifier: 'abc',
        event: 'download',
        at_time: Time.zone.parse('2026-07-10 12:00:00')
      )

      result = rollup_result

      expect(result.skipped_statistics).to eq(0)

      expect(
        described_class.run(result)
      ).to eq(true)
    end
  end
end
