# frozen_string_literal: true
require 'rails_helper'

describe FeaturedSearchesController, type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/detail/captions').to route_to(controller: 'featured_searches', slug: 'captions', action: 'show')
    end
  end
end
