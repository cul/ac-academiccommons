require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  before :each do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  # GET /users/sessions/new
  describe 'GET #new' do
    it 'redirects to :saml login' do
      get :new
      expect(response).to redirect_to user_saml_omniauth_authorize_path
    end
  end
end
