# frozen_string_literal: true

RSpec.describe 'session routes', type: :request do
  describe '/sign_in' do
    before do
      # request.env['devise.mapping'] = Devise.mappings[:user]
      get '/sign_in', params: { 'origin' => '/previous_page' }
    end

    it 'returns a 200 status code' do
      expect(response).to have_http_status(:success)
    end

    it 'saves the previous page in the session hash' do
      expect(session['after_sign_in_path']).to eq('/previous_page')
    end

    it 'renders the sign in redirect form' do
      expect(response.body).to include('<form id="signInForm"')
    end
  end
end
