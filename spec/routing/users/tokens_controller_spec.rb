# frozen_string_literal: true

require 'rails_helper'

describe Users::TokensController, type: :routing do
  describe 'routing' do
    it 'routes to #create' do
      expect(post: '/users/tu123/token').to route_to(controller: 'users/tokens', action: 'create', user_id: 'tu123')
    end
  end
end
