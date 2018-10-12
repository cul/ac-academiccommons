require 'rails_helper'

describe 'My Account', type: :feature do
  include_context 'non-admin user for feature'

  before do
    visit account_path
  end

  it 'renders my account title' do
    expect(page).to have_css('li.active', text: 'My Account')
  end

  it 'renders read and sign agreement link' do
    expect(page).to have_css('a', text: 'Read and sign the agreement')
  end

  it 'renders email preferences' do
    expect(page).to have_content('Email Preferences')
    expect(page).to have_content('You can change your Academic Commons email preferences below.')
  end

  context 'changing email preferences' do
    let(:email_preference) { EmailPreference.first }

    before do
      fill_in 'Preferred Email', with: 'tu123@example.com'
      check 'Unsubscribe all email communications'
      click_button 'Save'
    end

    it 'creates correct user preferences' do
      expect(email_preference.uni).to eql 'tu123'
      expect(email_preference.email).to eql 'tu123@example.com'
      expect(email_preference.unsubscribe).to be true
    end
  end
end
