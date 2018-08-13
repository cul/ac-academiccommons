require 'rails_helper'

RSpec.describe 'error pages', type: :request do
  describe '/admin' do
    context 'when user not admin' do
      include_context 'non-admin user for feature'

      before { get '/admin' }

      it 'returns 403 status code' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'render forbidden page' do
        expect(response.body).to include('Forbidden')
      end
    end

    context 'when user admin' do
      include_context 'admin user for feature'

      before { get '/admin' }

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
