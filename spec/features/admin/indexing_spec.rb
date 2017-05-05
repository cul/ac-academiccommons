require 'rails_helper'

RSpec.describe 'Admin Indexing', type: :feature do
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

  describe "indexing page" do
    include_context 'login admin user'
    before :each do
      visit 'admin/indexing'
    end

    it 'display ingest page' do
      expect(page).to have_content 'Index Records'
    end

    context 'when submitting page' do
      it 'starts index of items in solr core' do
        within('#index_all') do
          click_button 'Start'
        end
        expect(page).to have_content 'An index is running:'
      end
    end
  end
end
