# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog controller actions', type: :request do
  describe '/search' do
    it 'returns a 200 status when valid search params are supplied' do
      get '/search?per_page=20&sort=Published+Latest'
      expect(response.status).to eq(200)
    end

    it 'returns a 400 status when invalid search params are supplied' do
      get '/search?per_page=zzz&sort=zzz'
      expect(response.status).to eq(400)
    end
  end
end
