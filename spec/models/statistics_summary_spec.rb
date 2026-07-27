# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StatisticsSummary, type: :model do
  subject(:summary) do
    described_class.new(
      identifier: '12345',
      event: 'download',
      summary_month: Date.new(2026, 7, 1),
      count: 10
    )
  end

  it 'is valid with valid attributes' do
    expect(summary).to be_valid
  end

  it 'requires an identifier' do
    summary.identifier = nil

    expect(summary).not_to be_valid
    expect(summary.errors[:identifier]).to include("can't be blank")
  end

  it 'requires an event' do
    summary.event = nil

    expect(summary).not_to be_valid
    expect(summary.errors[:event]).to include("can't be blank")
  end

  it 'requires a summary_month' do
    summary.summary_month = nil

    expect(summary).not_to be_valid
    expect(summary.errors[:summary_month]).to include("can't be blank")
  end

  it 'requires a non-negative count' do
    summary.count = -1

    expect(summary).not_to be_valid
    expect(summary.errors[:count]).to be_present
  end

  it 'requires an integer count' do
    summary.count = 1.5

    expect(summary).not_to be_valid
    expect(summary.errors[:count]).to be_present
  end

  describe '.for_period' do
    let!(:june) do
      described_class.create!(
        identifier: '1',
        event: 'download',
        summary_month: Date.new(2026, 6, 1),
        count: 5
      )
    end

    let!(:july) do
      described_class.create!(
        identifier: '1',
        event: 'download',
        summary_month: Date.new(2026, 7, 1),
        count: 10
      )
    end

    let!(:august) do
      described_class.create!(
        identifier: '1',
        event: 'download',
        summary_month: Date.new(2026, 8, 1),
        count: 15
      )
    end

    it 'returns summaries whose months fall within the period' do
      results = described_class.for_period(
        Date.new(2026, 6, 15),
        Date.new(2026, 7, 20)
      )

      expect(results).to contain_exactly(june)
      expect(results).not_to include(august, july)
    end
  end
end
