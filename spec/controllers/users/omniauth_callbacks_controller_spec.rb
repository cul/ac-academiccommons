# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  let(:uid) { 'abc123' }
  let(:auth_hash) do
    OmniAuth::AuthHash.new({ 'uid' => uid, 'extra' => {} })
  end

  let(:cul_ldap_entry) do
    instance_double('Cul::LDAP::Entry', uni: 'abc123', email: 'abc123@columbia.edu', last_name: 'Doe', first_name: 'Jane')
  end

  before :each do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:cas] = auth_hash
    request.env['devise.mapping'] = Devise.mappings[:user]
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
    allow(Omniauth::Cul::Cas3).to receive(:validation_callback).and_return([uid, nil])
    allow_any_instance_of(Cul::LDAP).to receive(:find_by_uni).with(uid).and_return(cul_ldap_entry)
  end

  # GET :cas
  describe '#cas' do
    before :each do
       get :cas
    end

    it 'creates new user' do
      expect(User.count).to eq 1
    end

    it 'creates new user with correct details' do
      jane = User.first
      expect(jane.first_name).to eq 'Jane'
      expect(jane.last_name).to eq 'Doe'
      expect(jane.uid).to eq 'abc123'
      expect(jane.email).to eq 'abc123@columbia.edu'
    end
  end
end
