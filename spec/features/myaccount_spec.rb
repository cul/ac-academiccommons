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
      check 'Unsubscribe from all emails'
      click_button 'Save'
    end

    it 'creates correct user preferences' do
      expect(email_preference.uni).to eql 'tu123'
      expect(email_preference.email).to eql 'tu123@example.com'
      expect(email_preference.unsubscribe).to be true
    end

    it 'renders flash message' do
      expect(page).to have_content 'Successfully updated email preference.'
    end
  end

  context 'generating a new token' do
    before do
      click_button 'Generate Token'
    end

    it 'renders flash message' do
      expect(page).to have_content 'Successfully created API token.'
    end

    it 'shows the new token' do
      expect(page).to have_css('label', text: 'Personal MCP API Token')
    end
  end

  context 'refreshing a token' do
    let(:current_user) { User.find_by(uid: 'tu123') }

    before do
      FactoryBot.create(:mcp_token, authorizable: current_user)
      visit account_path
    end

    it 'displays the current token first' do
      expect(page).to have_css('label', text: 'Personal MCP API Token')
      expect(page).to have_field('Personal MCP API Token', with: 'mcp-token-value', disabled: true)
    end

    it 'creates a new token' do
      old_token = find_field('Personal MCP API Token', disabled: true).value
      click_button 'Generate New Token'
      new_token = find_field('Personal MCP API Token', disabled: true).value
      expect(old_token).not_to eq(new_token)
    end

    it 'renders flash message' do
      click_button 'Generate New Token'
      expect(page).to have_content 'Successfully refreshed API token.'
    end
  end

  context 'deleting a token' do
    let(:current_user) { User.find_by(uid: 'tu123') }

    before do
      FactoryBot.create(:mcp_token, authorizable: current_user)
      visit account_path
      click_button 'Delete Token'
    end

    it 'removes the token field' do
      expect(page).not_to have_field('Personal MCP API Token', disabled: true)
    end

    it 'renders flash message' do
      expect(page).to have_content 'Successfully deleted API token.'
    end

    it 'renders new token button' do
      expect(page).to have_button('Generate Token')
    end
  end
end
