# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog controller actions', type: :request, focus: true do # rubocop:disable RSpec/Focus
  describe '/search' do
    it 'returns a 200 status when valid search params are supplied' do
      get '/search?per_page=20&sort=Published+Latest'
      expect(response.status).to eq(200)
    end

    it 'ignores bad sort values' do
      get '/search?per_page=20&sort=zzz'
      expect(response.status).to eq(200)
    end

    # pending - ACHYDRA-842
    xit 'validates paging values' do
      get '/search?per_page=Bad+Value&sort=Published+Latest'
      expect(response.status).to eq(400)
    end

    it 'returns x-robots-tag none in headers' do
      get '/search?per_page=20&sort=Published+Latest'
      expect(response.headers['X-Robots-Tag']).to eq('none')
    end
  end

  describe '/show' do
    it 'does not return x-robots-tag none in headers' do
      get '/doi/10.7916/ALICE'
      expect(response.headers['X-Robots-Tag']).to be_nil
    end
  end
end
