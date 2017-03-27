require 'rails_helper'

RSpec.describe 'error pages', type: :request do
  include Warden::Test::Helpers
  
  describe '/admin' do
    let(:uid) { 'abc123' }

    context 'when user not admin' do
      before :each do
        OmniAuth.config.test_mode = true
        Rails.application.env_config["devise.mapping"] = Devise.mappings[:user]
        Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:saml]
        login_as User.new(uid: uid)
        get '/admin'
      end

      it 'returns 403 status code' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'render forbidden page' do
        expect(response).to render_template('errors/forbidden')
      end
    end
  end

  describe '/catalog/NOT_VALID_ID' do
    context 'when solr document id not valid' do
      before :each do
        get '/catalog/NOT_VALID_ID'
      end

      it 'returns 500 status code' do
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'renders record not found page' do
        expect(response).to render_template('errors/record_not_found')
      end
    end
  end
end
