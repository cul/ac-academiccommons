require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
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
    [{
      :mail      => 'abc123@columbia.edu',
      :sn        => 'Doe',
      :givenname => 'Jane'
    }]
  end

  before :each do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = saml_hash
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:saml]
    allow_any_instance_of(Net::LDAP).to receive(:search).with(ldap_request).and_return(ldap_response)
  end

  # GET :saml
  describe '#saml' do
    before :each do
      get :saml
    end
    # mock ldap response, what to do if response doesn't return?
    it 'creates new user' do
      expect(User.count).to eq 1
    end

    it 'creates new user with correct details' do
      jane = User.first
      expect(jane.first_name).to be eq 'Jane'
      expect(jane.last_name).to be eq 'Doe'
      expect(jane.uid).to be eq 'abc123'
      expect(jane.email).to be eq 'abc123@columbia.edu'
    end

    context 'on second login' do
      before :each do
        get :saml
      end

      it 'does not create a new record' do
        expect(User.count).to eq 1
      end

      it 'increases login count' do
        expect(User.first.sign_in_count).to eq 2
      end
    end
  end
end
