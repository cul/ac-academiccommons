# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SiteConfiguration, type: :model do
  let(:test_site_configuration) { FactoryBot.build(:site_configuration) }

  describe 'should be valid' do
    # TODO: fix mocks?
    it 'with singleton_guard, downloads_enabled, and deposits_enabled present' do
      expect(test_site_configuration).to be_valid
    end

    it 'with downloads_message and alert_message not present' do
      test_site_configuration.downloads_message = nil
      test_site_configuration.alert_message = nil
      expect(test_site_configuration).to be_valid
    end
  end

  describe 'should not be valid' do
    it 'when singleton_guard is nil' do
      test_site_configuration.singleton_guard = nil
      expect(test_site_configuration).not_to be_valid
    end

    it 'when singleton_guard is not 0' do
      test_site_configuration.singleton_guard = 1
      expect(test_site_configuration).not_to be_valid
    end

    it 'when downloads_enabled is nil' do
      test_site_configuration.downloads_enabled = nil
      expect(test_site_configuration).not_to be_valid
    end

    it 'when deposits_enabled is nil' do
      test_site_configuration.deposits_enabled = nil
      expect(test_site_configuration).not_to be_valid
    end
  end
end
