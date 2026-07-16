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

    before do
      travel_to(now)
    end

    after do
      travel_back
    end

    it 'deletes statistics older than the cutoff' do
      old_statistic = create_statistic(at_time: 1.year.ago - 1.day)
      recent_statistic = create_statistic(at_time: 1.year.ago + 1.day)

      described_class.call

      expect(
        Statistic.exists?(old_statistic.id)
      ).to be(false)

      expect(
        Statistic.exists?(recent_statistic.id)
      ).to be(true)
    end

    it 'accepts a custom cutoff' do
      statistic = Statistic.create!(
        identifier: 'custom',
        event: 'download',
        at_time: Date.new(2025, 1, 1)
      )

      described_class.call(
        before: Date.new(2025, 2, 1)
      )

      expect(
        Statistic.exists?(statistic.id)
      ).to be(false)
    end

    it 'returns the number of deleted rows' do
      Statistic.create!(
        identifier: 'abc',
        event: 'download',
        at_time: 2.years.ago
      )

      expect(
        described_class.call
      ).to eq(1)
    end
  end

  it 'deletes only a specified window' do
    inside = create_statistic(at_time: Time.zone.parse('2016-06-01'))
    outside = create_statistic(at_time: Time.zone.parse('2018-06-01'))

    described_class.call(
      from: Time.zone.parse('2016-01-01'),
      to: Time.zone.parse('2017-01-01')
    )

    expect(Statistic.exists?(inside.id)).to eq(false)
    expect(Statistic.exists?(outside.id)).to eq(true)
  end

  it 'requires from and to together' do
    [{ from: Time.zone.parse('2016-01-01') }, { to: Time.zone.parse('2017-01-01') }].each do |params|
      expect { described_class.call(**params) }
        .to raise_error(ArgumentError, 'from and to must be provided together')
    end
  end

  it 'does not allow before with from/to' do
    expect {
      described_class.call(
        before: Time.zone.parse('2017-01-01'),
        from: Time.zone.parse('2016-01-01'),
        to: Time.zone.parse('2017-01-01')
      )
    }.to raise_error(
      ArgumentError,
      'Specify either before or from/to, not both'
    )
  end

  it 'requires from to be before to' do
    expect {
      described_class.call(
        from: Time.zone.parse('2017-01-01'),
        to: Time.zone.parse('2016-01-01')
      )
    }.to raise_error(
      ArgumentError,
      'from must be before to'
    )
  end
end
