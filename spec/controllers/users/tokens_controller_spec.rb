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

  # PUT/PATCH /users/$uni/api_token
  describe 'PATCH #update' do
    before do
      FactoryBot.create(:token)
    end

    it 'redirects to /account' do
      patch :update, params: { user_id: 'tu123' }
      expect(response).to redirect_to account_path
    end

    it 'has a success flash message' do
      patch :update, params: { user_id: 'tu123' }
      expect(controller.flash).to be_key('success')
    end
  end

  # DELETE /users/$uni/api_token
  describe 'DELETE #destroy' do
    before do
      FactoryBot.build(:user, uid: 'tu123')
      user = User.find_by(uid: 'tu123')
      FactoryBot.create(:mcp_token, authorizable: user)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'redirects to /account' do
      delete :destroy, params: { user_id: 'tu123' }
      expect(response).to redirect_to account_path
    end

    it 'has a success flash message' do
      delete :destroy, params: { user_id: 'tu123' }
      expect(controller.flash).to be_key('success')
    end
  end
end
