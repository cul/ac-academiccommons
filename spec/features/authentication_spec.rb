# frozen_string_literal: true

require 'rails_helper'

describe 'authentication', type: :feature do
  context 'when user not logged in' do
    it 'contains log in link' do
      visit root_path
      expect(page).to have_link 'Log In', href: '/sign_in'
    end

    it 'visiting sign_in renders redirect form page' do
      # Turn off javascript for this test so that the redirect page can be tested
      Capybara.current_driver = :rack_test
      visit new_user_session_path
      expect(page).to have_content 'Redirecting you to be authenticated...'
    end
  end

  context 'when user logged in as non-admin' do
    include_context 'non-admin user for feature'
    it 'redirects access to protected pages to root path' do
      expect(page).to have_current_path root_path
    end
  end

  context 'when user logged in as admin' do
    include_context 'admin user for feature'
    it 'allows access to protected pages' do
      visit admin_path
      expect(page).to have_current_path admin_path
    end
  end
end
