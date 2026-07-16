# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Statistics::SummaryVerifier do
  let(:from) { Time.zone.parse('2026-07-01 00:00:00') }
  let(:to)   { Time.zone.parse('2026-08-01 00:00:00') }

  def create_statistic(identifier:, event:, at_time:)
    Statistic.create!(
      identifier: identifier,
      event: event,
      at_time: at_time
    )
  end

  def rollup_result
    Statistics::SummaryRollup.call(
      from: from,
      to: to
    )
  end

  describe '.call' do
    it 'passes when summaries match statistics' do
      create_statistic(
        identifier: 'abc',
        event: 'download',
        at_time: Time.zone.parse('2026-07-10 12:00:00')
      )

      result = rollup_result

      expect(
        described_class.call(result)
      ).to eq(true)
    end

    it 'raises when the raw statistic count does not match the rollup result' do
      create_statistic(identifier: 'abc', event: 'download', at_time: Time.zone.parse('2026-07-10 12:00:00'))

      result = rollup_result

      tampered_result = Statistics::SummaryRollupResult.new(
        from: result.from,
        to: result.to,
        events_processed: 99,
        summary_rows_written: result.summary_rows_written,
        months_processed: result.months_processed
      )

      expect {
        described_class.call(tampered_result)
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
        described_class.call(result)
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
        described_class.call(result)
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
        described_class.call(result)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError
      )
    end
  end
end
