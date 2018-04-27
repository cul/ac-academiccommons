require 'rails_helper'

RSpec.describe 'item redirect', type: :request do
  # Testing that /item requests correctly redirect to the resource. The handle
  # server redirects to request to /item.
  describe '/item' do
    it 'redirects to /doi/:doi' do
      get '/item/actest:1'
      expect(response).to redirect_to('/doi/10.7916/ALICE')
    end
  end

  describe '/catalog/:id' do
    it 'redirects to /doi/:doi' do
      get '/catalog/actest:1'
      expect(response).to redirect_to('/doi/10.7916/ALICE')
    end
  end
end
