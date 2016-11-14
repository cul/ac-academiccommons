require 'rails_helper'

RSpec.describe 'authentication', type: :routing do
  describe '/sign_in' do
    it 'redirects to saml login' do
      expect(get: '/sign_in').to route_to(
        controller: 'users/sessions',
        action: 'new'
      )
    end
  end
end
