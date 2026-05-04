# frozen_string_literal: true

require 'rails_helper'

describe CollectionsController, type: :routing do
  describe 'routing' do
    it 'routes to featured partners collection' do
      expect(get: '/explore/featured-partners').to route_to(
        controller: 'collections', category_slug: 'featured-partners', action: 'show'
      )
    end

    it 'routes to doctoral theses collection' do
      expect(get: '/explore/doctoral-theses').to route_to(
        controller: 'collections', category_slug: 'doctoral-theses', action: 'show'
      )
    end

    it 'routes to produced at columbia collection' do
      expect(get: '/explore/produced-at-columbia').to route_to(
        controller: 'collections', category_slug: 'produced-at-columbia', action: 'show'
      )
    end

    it 'routes to featured series collection' do
      expect(get: '/explore/featured-series').to route_to(
        controller: 'collections', category_slug: 'featured-series', action: 'show'
      )
    end

    it 'routes to columbia journals collection' do
      expect(get: '/explore/columbia-journals').to route_to(
        controller: 'collections', category_slug: 'columbia-journals', action: 'show'
      )
    end
  end
end
