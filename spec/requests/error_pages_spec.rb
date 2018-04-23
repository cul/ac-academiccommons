require 'rails_helper'

RSpec.describe 'error pages', type: :request do
  include Warden::Test::Helpers

  describe '/admin' do
    let(:uid) { 'abc123' }
    let(:ldap_user) do
      OpenStruct.new(uni: 'abc123', first_name: 'Jane', last_name: 'Doe')
    end

    before :each do
      OmniAuth.config.test_mode = true
      Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
      Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
      expect(AcademicCommons::LDAP).to receive(:find_by_uni).with('abc123').and_return(ldap_user)
      login_as user
      get '/admin'
    end

    context 'when user not admin' do
      let(:user) { User.new(uid: uid) }

      it 'returns 403 status code' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'render forbidden page' do
        expect(response.body).to include('Forbidden')
      end
    end

    context 'when user admin' do
      let(:user) { User.new(uid: uid, admin: true) }

      it 'returns 200 status code' do
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe '/solr_document/NOT_VALID_ID' do
    context 'when solr document id not valid' do
      before :each do
        get '/solr_document/NOT_VALID_ID'
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
