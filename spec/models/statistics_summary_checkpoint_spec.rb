# frozen_string_literal: true

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

  describe '.fetch!' do
    it 'returns the singleton checkpoint' do
      checkpoint = described_class.create!(
        processed_until: Time.current
      )

      expect(described_class.fetch!).to eq(checkpoint)
      expect(checkpoint.id).to eq(1)
    end

    it 'raises if no checkpoint exists' do
      expect {
        described_class.fetch!
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#advance_to!' do
    it 'updates the processed_until timestamp' do
      checkpoint = described_class.create!(
        processed_until: 1.day.ago
      )

      now = Time.current

      checkpoint.advance_to!(now)

      expect(checkpoint.reload.processed_until).to eq(now)
    end
  end
end
