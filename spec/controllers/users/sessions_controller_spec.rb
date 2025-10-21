require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  before :each do
    request.env['devise.mapping'] = Devise.mappings[:user]
    request.params['origin'] = '/previous_page'

    get :new
  end

  # GET /users/sessions/sign_in
  describe '#new' do
    before do
      get :new
    end

    it 'saves the previous route in the session hash' do
      expect(session['return_to']).to eq('/')
    end
  end
end
