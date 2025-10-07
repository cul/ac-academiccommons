require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller, focus: true do # rubocop:disable RSpec/Focus
  before :each do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  # GET /users/sessions/new
  describe 'GET #new' do
    it 'redirects to :cas login' do
      # TODO : change expectation condition
      get :new
      puts 'inside test'
      puts response.to_a
      puts response.body
      puts response.redirect_url
      puts response.response_code
      puts response.status
      puts response.message
      expect(response).to have_http_status(:success)
      expect(response.body).to include('method="post"')
      expect(response.body).to include(user_cas_omniauth_authorize_path)
    end
  end
end
