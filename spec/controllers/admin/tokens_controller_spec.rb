# frozen_string_literal: true

require 'rails_helper'

describe Admin::TokensController, type: :controller do
  # GET /admin/tokens
  describe 'GET #index' do
    include_examples 'authorization required' do
      let(:http_request) { get :index }
    end
  end

  # DELETE /admin/token/:token_id
  describe 'DELETE #destroy' do
    let(:token) { FactoryBot.create(:token) }

    include_examples 'authorization required', 302 do
      let(:http_request) { delete :destroy, params: { id: token.id } }
    end
  end
end
