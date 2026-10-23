require 'rails_helper'

describe AssetsController, type: :routing do
  describe 'routing' do
    it 'routes to #captions' do
      expect(get: '/doi/10.7916/foo/captions').to route_to(controller: 'assets', action: 'captions', id: '10.7916/foo')
    end
  end
end
