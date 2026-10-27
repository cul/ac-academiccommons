# frozen_string_literal: true

require 'rails_helper'

describe Admin::DataFeedsController, type: :controller do
  let(:test_data_feed) { FactoryBot.create(:data_feed) }
  let(:new_data_feed_params) do
    { data_feed: { key: 'new_key', search_fields_attributes: { '0' => { 'key' => 'key', 'value' => 'value' } } } }
  end

  # GET /admin/data_feeds
  describe 'GET #index' do
    include_examples 'authorization required' do
      let(:http_request) { get :index }
    end
  end

  describe 'PUT #create' do
    include_examples 'authorization required' do
      let(:http_request) { put :create, params: new_data_feed_params }
    end
  end

  describe 'GET #new' do
    include_examples 'authorization required' do
      let(:http_request) { get :new, params: { id: test_data_feed.id } }
    end
  end

  describe 'GET #edit' do
    include_examples 'authorization required' do
      let(:http_request) { get :edit, params: { id: test_data_feed.id } }
    end
  end

  describe 'PUT #update' do
    include_examples 'authorization required' do
      let(:http_request) { post :update, params: { id: test_data_feed.id, data_feed: { key: 'key-change' } } }
    end
  end

  describe 'DELETE #destroy' do
    include_examples 'authorization required', 302 do
      let(:http_request) { delete :destroy, params: { id: test_data_feed.id } }
    end
  end
end
