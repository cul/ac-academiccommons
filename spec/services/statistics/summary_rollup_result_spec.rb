# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Statistics::SummaryRollupResult do
  it 'stores the rollup results' do
    from = Time.zone.parse('2026-07-01 00:00:00')
    to   = Time.zone.parse('2026-08-01 00:00:00')

    result = described_class.new(
      from: from,
      to: to,
      events_processed: 15,
      summary_rows_written: 3,
      months_processed: [Date.new(2026, 7, 1)]
    )

    expect(result.from).to eq(from)
    expect(result.to).to eq(to)
    expect(result.events_processed).to eq(15)
    expect(result.summary_rows_written).to eq(3)
    expect(result.months_processed).to eq([Date.new(2026, 7, 1)])
  end
end
