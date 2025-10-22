# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::TokensController, type: :controller do
  include_context 'non-admin user for controller'

  # POST /users/$uni/api_token
  describe 'POST #create' do
    it 'redirects to /account' do
      post :create, params: { user_id: 'tu123' }
      expect(response).to redirect_to account_path
    end

    it 'has a success flash message' do
      post :create, params: { user_id: 'tu123' }
      expect(controller.flash).to be_key('success')
    end
  end
end
