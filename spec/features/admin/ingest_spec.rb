require 'rails_helper'

RSpec.describe 'Admin Ingest', type: :feature do
  shared_context 'login admin user' do
    let(:uid) { 'abc123' }
    let(:saml_hash) do
      OmniAuth::AuthHash.new({ 'uid' => uid, 'extra' => {} })
    end

    let(:ldap_request) do
      {
        :base => "o=Columbia University, c=US",
        :filter => Net::LDAP::Filter.eq("uid", uid)
      }
    end

    let(:ldap_response) do
      [{ :mail => 'abc123@columbia.edu', :sn => 'Doe', :givenname => 'Jane' }]
    end

    before :each do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:saml] = saml_hash
      Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
      Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:saml]
      allow_any_instance_of(Net::LDAP).to receive(:search).with(ldap_request).and_return(ldap_response)
      visit '/sign_in'
      User.find_by(uid: uid).update!(admin: 1)
    end
  end

  describe "ingest page" do
    include_context 'login admin user'
    before :each do
      visit 'admin/ingest'
    end

    it 'display ingest page' do
      expect(page).to have_content 'Ingest/update data'
    end

    context 'when submitting page' do
      before :each do
        allow(ACIndexing).to receive(:reindex).and_return({new_items: []})
      end

      it 'starts index of collection' do
        fill_in 'collections', with: 'collection:3'
        click_button 'Commit'
        expect(page).to have_content 'An ingest is running'
      end

      it 'starts index of item' do
        fill_in 'items', with: 'actest:1'
        click_button 'Commit'
        expect(page).to have_content 'An ingest is running'
      end

      it 'displays error if collection is not collection:3' do
        fill_in 'collections', with: 'not-collection:3'
        click_button 'Commit'
        expect(page).to have_content 'not-collection:3 is not a collection used by Academic Commons.'
        expect(page).not_to have_content 'Started ingest with PID'
      end
    end
  end
end
