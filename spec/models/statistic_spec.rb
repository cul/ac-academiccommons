require 'rails_helper'

RSpec.describe Statistic, type: :model do
  describe '.event_count' do
    it 'checks event param' do
      expect {
        Statistic.event_count('actest:1', 'foo')
      }.to raise_error "event must one of #{Statistic::EVENTS}"
    end

    it 'checks asset_pids' do
      expect {
        Statistic.event_count(1, 'foo')
      }.to raise_error 'pids must be an Array or String'
    end

    context 'when query is not limited by date' do
      it 'returns correct counts' do
        FactoryGirl.create_list(:view_stat, 3, identifier: 'actest:1')
        FactoryGirl.create(:view_stat, identifier: 'actest:2')
        expect(
          Statistic.event_count(['actest:1', 'actest:2', 'actest:3'], Statistic::VIEW)
        ).to match('actest:1' => 3, 'actest:2' => 1)
      end
    end

    context 'when query is limited by date' do
      before :each do
        FactoryGirl.create(:view_stat, at_time: Time.local(2015, 12, 31, 23, 00))
        FactoryGirl.create(:view_stat, at_time: Time.local(2015, 1, 1))
        FactoryGirl.create(:view_stat, at_time: Time.local(2015, 1, 31, 23, 00))
        FactoryGirl.create(:view_stat, at_time: Time.local(2015, 1, 21, 4, 00))
        FactoryGirl.create(:view_stat, at_time: Time.local(2015, 2, 1))
        FactoryGirl.create(:view_stat, identifier: 'actest:2', at_time: Time.local(2015, 12, 5))
      end

      it 'returns correct counts for Jan 2015' do
        expect(
          Statistic.event_count('actest:1', Statistic::VIEW, start_date: Date.civil(2015, 1), end_date: Date.civil(2015, 1, -1))
        ).to match('actest:1' => 3)
      end

      it 'returns correct counts for Feb 2015' do
        expect(
          Statistic.event_count('actest:1', Statistic::VIEW, start_date: Date.civil(2015, 2), end_date: Date.civil(2015, 2, -1))
        ).to match('actest:1' => 1)
      end

      it 'returns correct counts for Dec 2015' do
        expect(
          Statistic.event_count(['actest:1', 'actest:2'], Statistic::VIEW, start_date: Date.civil(2015, 12), end_date: Date.civil(2015, 12, -1))
        ).to match('actest:1' => 1, 'actest:2' => 1)
      end
    end
  end
end
