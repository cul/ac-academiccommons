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
      from: 1.day.ago.beginning_of_day,
      to: Time.current,
      events_processed: 10,
      summary_rows_written: 1
    )
  end

  before do
    allow(
      StatisticsSummaryCheckpoint
    ).to receive(:fetch!)
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

  it 'prunes after updating' do
    described_class.call

    expect(
      Statistics::Pruner
    ).to have_received(:call)
      .with(
        before: kind_of(ActiveSupport::TimeWithZone)
      )
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
end
