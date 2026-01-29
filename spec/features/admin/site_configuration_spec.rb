# frozen_string_literal: true

require 'rails_helper'

describe 'site configuration', type: :feature do
  include_context 'admin user for feature'
  before do
    FactoryBot.create(:site_configuration)
    visit edit_admin_site_configuration_path
  end

  context 'alert message configuration' do
    it 'has the alert message form' do
      expect(page).to have_css 'div#alert-message-form'
    end

    it 'renders existing alert message in the form' do
      within 'div#alert-message-form' do
        expect(page).to have_field 'alert_message', with: 'Test alert message'
      end
    end

    it 'displays alert message in site banner when set' do
      within 'div#alert-message-form' do
        fill_in 'alert_message', with: 'This is a new test alert message.'
        click_button 'Submit'
      end
      within 'div.alert-box' do
        expect(page).to have_content 'This is a new test alert message.'
      end
    end

    it 'does not display alert message in site banner when not set' do
      within 'div#alert-message-form' do
        fill_in 'alert_message', with: ''
        click_button 'Submit'
      end
    end

    it 'removes an alert message from site banner when empty form submitted' do
      within 'div.alert-box' do
        expect(page).to have_content 'Test alert message' # ensure message initially set
      end
      within 'div#alert-message-form' do
        fill_in 'alert_message', with: ''
        click_button 'Submit'
      end
      expect(page).not_to have_content 'div.alert-box'
    end
  end

  context 'download configuration' do
    it 'has the downloads toggle form' do
      expect(page).to have_css 'div#downloads-toggle-form'
    end

    it 'renders the existing downloads toggle state' do
      within 'div#downloads-toggle-form' do
        # Factory sets downloads_enabled to true
        expect(page).to have_button 'Disable Downloads'
      end
    end

    it 'has the set download message form' do
      expect(page).to have_css 'div#downloads-message-form'
    end

    it 'renders the existing downloads message in the form' do
      within 'div#downloads-message-form' do
        expect(page).to have_field 'downloads_message', with: 'Test downloads message'
      end
    end

    describe 'when downloads toggled off' do
      before do
        within 'div#downloads-toggle-form' do
          click_button 'Disable Downloads'
        end
      end

      it 'disabled downloading on item page when toggled off' do
        visit root_path
        visit solr_document_path('10.7916/ALICE') # Visit an item page
        # click_link 'Test Deposit' # from factory
        expect(page).to have_content 'Test downloads message'
      end

      it 'displays the downloads disabled message set in the form' do
        within 'div#downloads-message-form' do
          fill_in 'downloads_message', with: '(Custom message) Downloads are currently disabled for maintenance.'
          click_button 'Save Message'
        end
        visit root_path
        visit solr_document_path('10.7916/ALICE') # Visit an item page
        expect(page).to have_content '(Custom message) Downloads are currently disabled for maintenance.'
      end
    end

    describe 'when downloads toggled on' do
      it 'enables downloading on item page when toggled on' do
        visit solr_document_path('10.7916/ALICE') # Visit an item page
        expect(page).to have_css 'a.download-button'
      end
    end
  end

  context 'deposits configuration' do
    it 'has the deposits toggle form' do
      expect(page).to have_css 'div#deposits-toggle-form'
    end

    it 'renders the existing deposits toggle state' do
      within 'div#deposits-toggle-form' do
        expect(page).to have_button 'Disable Deposits'
      end
    end

    describe 'when deposits are enabled' do
      it "renders 'Add New Work' tab when deposits are enabled" do
        within 'div#dashboard-nav' do
          expect(page).to have_content 'Add New Work'
        end
      end

      it 'allows navigation to new upload form when deposits are enabled' do
        visit new_upload_path
        expect(page).to have_current_path new_upload_path
      end

      it "renders 'Upload Your Research' button on home page" do
        visit root_path
        expect(page).to have_content 'Upload Your Research'
      end

      it "includes 'Upload' link in user utility links navbar" do
        within 'div#links-navbar' do
          expect(page).to have_link 'Upload', href: '/upload'
        end
      end
    end

    describe 'when deposits are disabled' do
      before do
        within 'div#deposits-toggle-form' do
          click_button 'Disable Deposits'
        end
      end

      it "does not render 'Add New Work' tab when deposits are disabled" do
        within 'div#dashboard-nav' do
          expect(page).not_to have_content 'Add New Work'
        end
      end

      it 'redirects to home page when deposits are disabled and user attempts to access new deposit page' do
        visit new_upload_path
        expect(page).to have_current_path root_path
      end

      it 'displays deposits disabled message in admin self-deposits section' do
        visit admin_deposits_path
        expect(page).to have_content 'Deposits are currently disabled.'
      end

      it "does not render 'Upload Your Research' button on home page" do
        visit root_path
        expect(page).not_to have_content 'Upload Your Research'
      end

      it "does not include 'Upload' link in user utility links navbar" do
        within 'div#links-navbar' do
          expect(page).not_to have_link 'Upload', href: '/upload'
        end
      end
    end
  end
end
