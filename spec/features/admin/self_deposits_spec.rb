# frozen_string_literal: true

require 'rails_helper'

# N.B.: we test for the creation of a new self deposit via the upload feature spec (features/upload_spec.rb)
describe 'self deposits management by admin', type: :feature do
  include_context 'admin user for feature'

  let!(:deposit) { FactoryBot.create(:deposit) }

  it 'redirects to login if not authorized' do
    logout(:user)
    visit admin_deposits_path
    expect(page).to have_current_path new_user_session_path
  end

  # Below is gen
  context 'when visiting self deposits index page' do
    before do
      visit admin_deposits_path
    end

    it 'displays the self deposits list' do
      expect(page).to have_content 'Self-Deposits'
      expect(page).to have_content 'Test Deposit'
    end

    it 'has link to view each self deposit' do
      expect(page).to have_link 'Test Deposit', href: admin_deposit_path(deposit)
    end
  end

  context 'when viewing a self deposit' do
    before do
      visit admin_deposit_path(deposit)
    end

    it 'displays the self deposit details' do # rubocop:disable RSpec/MultipleExpectations
      expect(page).to have_content 'Test Deposit'
      expect(page).to have_content 'Jane Doe'
      expect(page).to have_content 'This deposit is just for testing purposes.'
      expect(page).to have_content '2018'
      expect(page).to have_content 'https://www.example.com'
      expect(page).to have_content 'http://rightsstatements.org/vocab/InC/1.0/'
      expect(page).to have_content 'https://creativecommons.org/licenses/by/4.0/'
      expect(page).to have_content 'true'
      expect(page).to have_content 'false'
    end

    it 'has the file attachment download link' do
      expect(page).to have_link 'test_file.txt', href: rails_blob_path(deposit.files.first, disposition: 'attachment')
    end

    it 'has link to go back to index' do
      expect(page).to have_link 'Back to Self-Deposits', href: admin_deposits_path
    end
  end
end
