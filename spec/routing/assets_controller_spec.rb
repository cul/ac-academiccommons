require 'rails_helper'

describe AssetsController, type: :routing do
  describe 'routing' do
    it 'routes to #captions' do
      expect(get: '/doi/foo/captions').to route_to(controller: 'assets', action: 'captions', id: 'foo')
    end
  end
end
