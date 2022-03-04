# frozen_string_literal: true
require 'rails_helper'

describe Admin::FeaturedSearchesController, type: :controller do
  let(:id) { 'foo' }

  shared_context 'mock_feature' do
    let(:featured_search) { instance_double(FeaturedSearch, slug: id) }

    before do
      allow(FeaturedSearch).to receive(:find).with(id).and_return(featured_search)
    end
  end

  describe 'GET index' do
    include_examples 'authorization required' do
      let(:http_request) { get :index }
    end
  end
  describe 'GET edit' do
    include_context 'mock_feature'

    include_examples 'authorization required' do
      let(:http_request) { get :edit, params: { id: id } }
    end
  end
  describe 'DELETE destroy' do
    include_context 'mock_feature'

    include_examples 'authorization required', 302 do
      before { allow(featured_search).to receive(:destroy).and_return(true) }
      let(:http_request) { delete :destroy, params: { id: id } }
    end
  end
end
