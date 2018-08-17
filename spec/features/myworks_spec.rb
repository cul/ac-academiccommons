require 'rails_helper'

describe 'myworks', type: :feature do
  include_context 'non-admin user for feature'

  before do
    FactoryBot.create(:view_stat)
    FactoryBot.create(:download_stat)
    FactoryBot.create(:download_stat)
    FactoryBot.create(:view_stat, at_time: Time.current - 1.month)
    visit myworks_path
  end

  it 'displays available works' do
    expect(page).to have_content 'Alice\'s Adventures in Wonderland'
  end

  it 'displays correct download statistics' do
    within :xpath, '//tr/td/a[@href="/doi/10.7916/ALICE"]/../..' do
      expect(page).to have_xpath 'td[2]', text: '0'
      expect(page).to have_xpath 'td[3]', text: '2'
    end
  end

  it 'displays correct view statistics' do
    within :xpath, '//tr/td/a[@href="/doi/10.7916/ALICE"]/../..' do
      expect(page).to have_xpath 'td[4]', text: '1'
      expect(page).to have_xpath 'td[5]', text: '2'
    end
  end
end
