# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Statistics::Updater do
  let(:checkpoint) do
    instance_spy(
      StatisticsSummaryCheckpoint,
      processed_until: 1.day.ago
    )
  end

  let(:result) do
    instance_double(
      Statistics::SummaryRollupResult,
      from: checkpoint.processed_until,
      to: Time.current,
      events_processed: 10,
      summary_rows_written: 1
    )
  end

  before do
    allow(
      StatisticsSummaryCheckpoint
    ).to receive(:current)
      .and_return(checkpoint)

    allow(
      Statistics::SummaryRollup
    ).to receive(:call)
      .and_return(result)

    allow(
      Statistics::SummaryVerifier
    ).to receive(:call)

    allow(
      Statistics::Pruner
    ).to receive(:call)
  end

  it 'rolls up statistics and advances the checkpoint' do
    described_class.call

    expect(
      Statistics::SummaryRollup
    ).to have_received(:call)

    expect(
      Statistics::SummaryVerifier
    ).to have_received(:call)
      .with(result)

    expect(
      checkpoint
    ).to have_received(:advance_to!)
  end

  it 'verifies before advancing the checkpoint' do
    order = []

    allow(
      Statistics::SummaryVerifier
    ).to receive(:call) do
      order << :verify
    end

    allow(
      checkpoint
    ).to receive(:advance_to!) do
      order << :checkpoint
    end

    described_class.call

    expect(order).to eq(
      [:verify, :checkpoint]
    )
  end

  it 'does not advance the checkpoint if verification fails' do
    allow(
      Statistics::SummaryVerifier
    ).to receive(:call)
      .and_raise(
        Statistics::SummaryVerifier::VerificationError
      )

    expect {
      described_class.call
    }.to raise_error(
      Statistics::SummaryVerifier::VerificationError
    )

    expect(
      checkpoint
    ).not_to have_received(:advance_to!)
  end

  # These examples use real ActiveRecord objects to confirm the DB transaction rolls back on failure
  context 'when checking transactional integrity' do
    def create_statistic(identifier:, event:, at_time:)
      Statistic.create!(
        identifier: identifier,
        event: event,
        at_time: at_time
      )
    end

    it 'does not advance the persisted checkpoint if verification fails' do
      checkpoint = StatisticsSummaryCheckpoint.current
      original_processed_until = checkpoint.processed_until

      from = original_processed_until
      to = from + 1.day

      create_statistic(identifier: 'abc', event: 'download', at_time: from + 1.hour)

      allow(
        Statistics::SummaryVerifier
      ).to receive(:call)
        .and_raise(Statistics::SummaryVerifier::VerificationError)

      expect {
        described_class.call(to_date: to)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError
      )

      expect(checkpoint.reload.processed_until).to eq(original_processed_until)
    end

    it 'rolls back summary rows written earlier in the same failed transaction' do
      checkpoint = StatisticsSummaryCheckpoint.current
      from = checkpoint.processed_until
      to = from + 1.day

      create_statistic(identifier: 'abc', event: 'download', at_time: from + 1.hour)

      allow(
        Statistics::SummaryVerifier
      ).to receive(:call)
        .and_raise(Statistics::SummaryVerifier::VerificationError)

      expect {
        described_class.call(to_date: to)
      }.to raise_error(
        Statistics::SummaryVerifier::VerificationError
      )

      expect(StatisticsSummary.count).to eq(0)
    end
  end
end
