# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Statistics::Pruner do
  def create_statistic(at_time:)
    Statistic.create!(
      identifier: 'abc',
      event: 'download',
      at_time: at_time
    )
  end

  describe '.call' do
    let(:now) { Time.zone.parse('2026-07-13 12:00:00') }
    let(:checkpoint_time) { StatisticsSummaryCheckpoint.current.processed_until }
    let(:cutoff_time) { checkpoint_time - 1.year }

    before do
      travel_to(now)
    end

    after do
      travel_back
    end

    it 'deletes statistics older than 1 year before the checkpoint by default' do
      old_statistic = create_statistic(at_time: cutoff_time - 1.day)
      recent_statistic = create_statistic(at_time: cutoff_time + 1.day)

      described_class.call

      expect(Statistic.exists?(old_statistic.id)).to be(false)
      expect(Statistic.exists?(recent_statistic.id)).to be(true)
    end

    it 'returns the number of deleted rows' do
      create_statistic(at_time: cutoff_time - 2.days)

      expect(described_class.call).to eq(1)
    end

    it 'deletes up to a specified "to" timestamp when valid' do
      valid_to = cutoff_time - 1.month
      inside  = create_statistic(at_time: valid_to - 1.day)
      outside = create_statistic(at_time: valid_to + 1.day)

      described_class.call(to_date: valid_to)

      expect(Statistic.exists?(inside.id)).to eq(false)
      expect(Statistic.exists?(outside.id)).to eq(true)
    end

    it 'raises an ArgumentError if "to" is not at least 1 year older than the checkpoint' do
      invalid_to = cutoff_time + 1.day

      expect { described_class.call(to_date: invalid_to) }
        .to raise_error(
          ArgumentError,
          'to date must be at least 1 year older than the checkpoint'
        )
    end
  end
end
