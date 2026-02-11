# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  include_context 'mock ldap request' # provides uni, cul_ldap, and cul_ldap entry as well as mocks LDAP methods

  let(:auth_hash) do
    OmniAuth::AuthHash.new({ 'uid' => uni, 'extra' => {} })
  end

  before :each do
    request.env['devise.mapping'] = Devise.mappings[:user]
    allow(Omniauth::Cul::ColumbiaCas).to receive(:validation_callback).and_return([uni, nil])
  end

  # GET :cas
  describe '#cas' do
    before :each do
      get :columbia_cas
    end

    it 'creates new user' do
      expect(User.count).to eq 1
    end

    it 'creates new user with correct details' do
      jane = User.first
      expect(jane.first_name).to eq 'User'
      expect(jane.last_name).to eq 'Test'
      expect(jane.uid).to eq 'tu123'
      expect(jane.email).to eq 'tu123@columbia.edu'
    end
  end
end
