require 'rails_helper'

RSpec.describe StatisticsSummaryCheckpoint, type: :model do
  describe '.current' do
    it 'creates the checkpoint if it does not exist' do
      expect {
        described_class.current
      }.to change(described_class, :count).by(1)
    end

    it 'returns the existing checkpoint' do
      checkpoint = described_class.current

      expect(described_class.current).to eq(checkpoint)
      expect(described_class.count).to eq(1)
    end

    it 'initializes processed_until to the Unix epoch' do
      checkpoint = described_class.current

      expect(checkpoint.processed_until).to eq(Time.at(0).utc)
    end
  end

  describe '#advance_to!' do
    it 'updates processed_until' do
      checkpoint = described_class.current

      new_time = Time.zone.parse('2026-07-10 12:00:00 UTC')

      checkpoint.advance_to!(new_time)

      expect(checkpoint.reload.processed_until).to eq(new_time)
    end
  end
end
