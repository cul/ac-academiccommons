# frozen_string_literal: true

RSpec.describe 'session routes', type: :request do
  describe '/sign_in' do
    before do
      get '/sign_in', headers: { 'HTTP_REFERER' => 'http://localhost:3000/previous_page' }
    end

    it 'returns a 200 status code' do
      expect(response).to have_http_status(:success)
    end

    it 'saves the previous page in the session hash' do
      expect(session['return_to']).to eq('/previous_page')
    end

    it 'renders the sign in redirect form' do
      expect(response.body).to include('<form id="signInForm"')
    end
  end
end
