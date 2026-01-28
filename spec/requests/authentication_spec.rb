# frozen_string_literal: true

require 'rails_helper'

describe 'authentication', type: :request do
  include_context 'mock ldap request' # provides uni, cul_ldap, and cul_ldap entry as well as mocks LDAP methods
  describe 'when user not logged in' do
    it 'redirects access to protected pages to sign in page' do
      get '/admin'
      expect(response).to redirect_to new_user_session_path
    end
  end

  describe 'when user signed in as non-admin' do
    before do
      user = FactoryBot.create(:user)
      sign_in user
      get '/admin'
    end

    it 'renders error page when accessing admin-only routes' do
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include 'You do not have access'
    end
  end

  describe 'when user is admin' do
    before do
      admin_user = FactoryBot.create(:admin)
      sign_in admin_user
      get '/admin'
    end

    it 'allows access to admin-only routes' do
      expect(response).to render_template(:index)
    end
  end
end
