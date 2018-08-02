require 'rails_helper'

RSpec.describe 'error pages', type: :request do
  include Warden::Test::Helpers

  describe '/admin' do
    let(:uid) { 'abc123' }
    let(:ldap) { instance_double('Cul::LDAP') }
    let(:cul_ldap_user) do
      instance_double('Cul::LDAP::User', uid: 'abc123', first_name: 'Jane', last_name: 'Doe', email: 'abc123@columbia.edu')
    end

    before :each do
      OmniAuth.config.test_mode = true
      Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
      Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
      allow(Cul::LDAP).to receive(:new).and_return(ldap)
      allow(ldap).to receive(:find_by_uni).with('abc123').and_return(cul_ldap_user)
      login_as user
      get '/admin'
    end

    context 'when user not admin' do
      let(:user) { User.create(uid: uid) }

      it 'returns 403 status code' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'render forbidden page' do
        expect(response.body).to include('Forbidden')
      end
    end

    context 'when user admin' do
      let(:user) { User.create(uid: uid, role: User::ADMIN) }

      it 'returns 200 status code' do
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe '/doi/NOT_VALID_ID' do
    context 'when doi not valid' do
      before :each do
        get '/doi/NOT_VALID_ID'
      end

      it 'returns 500 status code' do
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'renders record not found page' do
        expect(response.body).to include('Record Not Found')
      end
    end
  end
end
