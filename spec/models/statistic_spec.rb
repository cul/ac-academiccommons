require 'rails_helper'

RSpec.describe Statistic, type: :model do
  describe '.per_identifier' do
    it 'checks event param' do
      expect {
        Statistic.per_identifier('actest:1', 'foo')
      }.to raise_error "event must one of #{Statistic::EVENTS}"
    end

    it 'checks asset_pids' do
      expect {
        Statistic.per_identifier(1, 'foo')
      }.to raise_error 'asset_pids must be an Array or String'
    end

    it 'returns correct count hash' do
      FactoryGirl.create_list(:view_stat, 3, identifier: 'actest:1')
      FactoryGirl.create(:view_stat, identifier: 'actest:2')
      expect(
        Statistic.per_identifier( ['actest:1', 'actest:2', 'actest:3'], Statistic::VIEW_EVENT)
      ).to match('actest:1' => 3, 'actest:2' => 1)
    end
  end
end
