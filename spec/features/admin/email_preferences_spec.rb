# frozen_string_literal: true

require 'rails_helper'

describe 'admin email preferences management', type: :feature do
  include_context 'admin user for feature'

  before do
    FactoryBot.create(:email_preference)
  end

  it 'redirects to login if not authorized' do
    logout(:user)
    visit admin_email_preferences_path
    expect(page).to have_current_path new_user_session_path
  end

  context 'when visiting email preferences index page' do
    before do
      visit admin_email_preferences_path
    end

    it 'displays the email preferences list' do
      expect(page).to have_content 'Email Preferences'
      expect(page).to have_content 'testuser@example.com'
    end

    it 'has link to create new email preference' do
      expect(page).to have_link 'Create New Email Preference', href: new_admin_email_preference_path
    end

    it 'has edit buttons for each email preference' do
      expect(page).to have_link 'Edit', href: edit_admin_email_preference_path(EmailPreference.first)
    end

    it 'has delete buttons for each email preference' do
      expect(page).to have_button 'Destroy'
    end
  end

  context 'when creating a new email preference' do
    before do
      visit new_admin_email_preference_path
    end

    it 'has the email preference form' do
      expect(page).to have_content 'New Email Preference'
      expect(page).to have_selector('[data-testid="email-preference-form"]')
    end

    it 'has a go back to index link' do
      expect(page).to have_link 'Back to Email Preferences', href: admin_email_preferences_path
    end

    it 'flashes error when creating with missing uni' do
      fill_in 'email_preference[uni]', with: ''
      click_button 'Create Email preference'
      expect(page).to have_css 'div.alert-dismissible'
    end

    it 'displays the created email preference when successful' do
      fill_in 'email_preference[uni]', with: 'newuser123'
      check 'email_preference[unsubscribe]'
      fill_in 'email_preference[email]', with: 'newuser123preference@example.com'
      click_button 'Create Email preference'
      expect(page).to have_content 'Email Preference'
      expect(page).to have_content 'newuser123'
      expect(page).to have_content 'true'
      expect(page).to have_content 'newuser123preference@example.com'
    end

    it 'flashes success message when created successfully' do
      fill_in 'email_preference[uni]', with: 'newuser123'
      check 'email_preference[unsubscribe]'
      fill_in 'email_preference[email]', with: 'newuser123preference@example.com'
      click_button 'Create Email preference'
      expect(page).to have_content 'Successfully created email preference.'
    end

    context 'when editing an existing email preference' do
      before do
        visit edit_admin_email_preference_path(EmailPreference.first)
      end

      it 'has the email preference form' do
        expect(page).to have_content 'Edit Email Preference'
        expect(page).to have_selector('[data-testid="email-preference-form"]')
      end

      it 'displays existing values in the form fields' do
        expect(find_field('email_preference[uni]').value).to eq 'testuser'
        expect(find_field('email_preference[unsubscribe]').checked?).to be false
        expect(find_field('email_preference[email]').value).to eq 'testuser@example.com'
      end

      it 'has a go back to index link' do
        expect(page).to have_link 'Back to Email Preferences', href: admin_email_preferences_path
      end

      it 'flashes error when updating with missing uni' do
        fill_in 'email_preference[uni]', with: ''
        click_button 'Update Email preference'
        expect(page).to have_css 'div.alert-dismissible'
      end

      it 'displays the updated email preference when successful' do
        check 'email_preference[unsubscribe]'
        fill_in 'email_preference[email]', with: 'updateduser@example.com'
        click_button 'Update Email preference'
        expect(page).to have_content 'testuser' # not changed
        expect(page).to have_content 'true'
        expect(page).to have_content 'updateduser@example.com'
      end

      it 'flashes success message when updated successfully' do
        fill_in 'email_preference[email]', with: 'updateduser123@example.com'
        click_button 'Update Email preference'
        expect(page).to have_content 'Successfully updated email preference.'
      end
    end
  end
end
