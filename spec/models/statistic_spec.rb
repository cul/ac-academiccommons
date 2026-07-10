require 'rails_helper'

RSpec.describe Statistic, type: :model do

  describe '.merge_stats' do
    before :each do
      FactoryBot.create_list(:view_stat, 2)
      FactoryBot.create(:download_stat, identifier: '10.7916/ALICE')
      FactoryBot.create(:view_stat, identifier: 'ac:duplicate')
      FactoryBot.create(:download_stat, identifier: 'ac:duplicate')
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
      }.to raise_error "event must one of #{Statistic::EVENTS}"
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

  describe '.between' do
    let!(:before) do
      Statistic.create!(
        identifier: '1',
        event: 'download',
        at_time: Time.zone.parse('2026-07-09 23:59')
      )
    end

    let!(:inside) do
      Statistic.create!(
        identifier: '1',
        event: 'download',
        at_time: Time.zone.parse('2026-07-10 12:00')
      )
    end

    let!(:after) do
      Statistic.create!(
        identifier: '1',
        event: 'download',
        at_time: Time.zone.parse('2026-07-11 00:01')
      )
    end

    it 'returns records within the range' do
      results = Statistic.between(
        Time.zone.parse('2026-07-10 00:00'),
        Time.zone.parse('2026-07-10 23:59:59')
      )

      expect(results).to contain_exactly(inside)
    end
  end
end
