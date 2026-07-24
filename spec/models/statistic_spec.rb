require 'rails_helper'

RSpec.describe Statistic, type: :model do

  describe '.merge_stats' do
    before :each do
      FactoryBot.create_list(:view_stat, 2)
      FactoryBot.create(:download_stat, identifier: '10.7916/ALICE')
      FactoryBot.create(:view_stat, identifier: 'ac:duplicate')
      FactoryBot.create(:download_stat, identifier: 'ac:duplicate')
      rebuild_statistics_summary!
    end

    it 'merges statistics correctly' do
      expect(Statistic.where(identifier: 'ac:duplicate').count).to be 2
      expect(Statistic.where(identifier: '10.7916/ALICE').count).to be 3
      Statistic.merge_stats('10.7916/ALICE', 'ac:duplicate')
      expect(Statistic.where(identifier: '10.7916/ALICE').count).to be 5
      expect(Statistic.where(identifier: 'ac:duplicate').count).to be 0
    end
  end

  describe '.event_count' do
    it 'checks event param' do
      expect {
        Statistic.event_count('10.7916/ALICE', 'foo')
      }.to raise_error "event must be one of #{Statistic::EVENTS}"
    end

    it 'checks asset_pids' do
      expect {
        Statistic.event_count(1, 'foo')
      }.to raise_error 'ids must be an Array or String'
    end

    context 'when query is not limited by date' do
      it 'returns correct counts' do
        FactoryBot.create_list(:view_stat, 3, identifier: '10.7916/ALICE')
        FactoryBot.create(:view_stat, identifier: '10.7916/TESTDOC2')
        rebuild_statistics_summary!
        expect(
          Statistic.event_count(['10.7916/ALICE', '10.7916/TESTDOC2', 'actest:3'], Statistic::VIEW)
        ).to match('10.7916/ALICE' => 3, '10.7916/TESTDOC2' => 1)
      end
    end

    context 'when query is limited by date' do
      before :each do
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 12, 31, 23, 0))
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 1, 1))
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 1, 31, 23, 0))
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 1, 21, 4, 0))
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 2, 1))
        FactoryBot.create(:view_stat, identifier: '10.7916/TESTDOC2', at_time: Time.local(2015, 12, 5))
        rebuild_statistics_summary!
      end

      it 'returns correct counts for Jan 2015' do
        expect(
          Statistic.event_count('10.7916/ALICE', Statistic::VIEW, start_date: Date.civil(2015, 1), end_date: Date.civil(2015, 1, -1))
        ).to match('10.7916/ALICE' => 3)
      end

      it 'returns correct counts for Feb 2015' do
        expect(
          Statistic.event_count('10.7916/ALICE', Statistic::VIEW, start_date: Date.civil(2015, 2), end_date: Date.civil(2015, 2, -1))
        ).to match('10.7916/ALICE' => 1)
      end

      it 'returns correct counts for Dec 2015' do
        expect(
          Statistic.event_count(['10.7916/ALICE', '10.7916/TESTDOC2'], Statistic::VIEW, start_date: Date.civil(2015, 12), end_date: Date.civil(2015, 12, -1))
        ).to match('10.7916/ALICE' => 1, '10.7916/TESTDOC2' => 1)
      end
    end
  end

  describe '#rollup_eligible?' do
    subject(:statistic) { FactoryBot.build(:statistic, identifier: identifier, event: event, at_time: at_time) }

    context 'with all required attributes' do
      let(:identifier) { 'abc123' }
      let(:event) { 'download' }
      let(:at_time) { Time.current }

      it { is_expected.to be_rollup_eligible }
    end

    context 'without an identifier' do
      let(:identifier) { nil }
      let(:event) { 'view' }
      let(:at_time) { Time.current }

      it { is_expected.not_to be_rollup_eligible }
    end

    context 'without an event' do
      let(:identifier) { 'abc123' }
      let(:event) { nil }
      let(:at_time) { Time.current }

      it { is_expected.not_to be_rollup_eligible }
    end

    context 'without an at_time' do
      let(:identifier) { 'abc123' }
      let(:event) { 'view' }
      let(:at_time) { nil }

      it { is_expected.not_to be_rollup_eligible }
    end
  end
end
