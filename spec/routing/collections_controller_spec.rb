# frozen_string_literal: true

require 'rails_helper'

describe CollectionsController, type: :routing do
  describe 'routing' do
    it 'routes to featured partners collection' do
      expect(get: '/explore/featured').to route_to(controller: 'collections', category_id: 'featured', action: 'show')
    end
  end
end
