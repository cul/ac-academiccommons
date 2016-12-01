require 'rails_helper'

RSpec.describe 'item redirect', type: :request do
  # Testing that /item requests correctly redirect to the resource. The handle
  # server redirects to request to /item.
  describe '/item' do
    it 'redirects to /catalog' do
      get '/item/ac:010101'
      expect(response).to redirect_to('/catalog/ac:010101')
    end
  end
end
