require 'rails_helper'

describe Admin::AlertMessagesController, type: :controller do
  describe 'GET edit' do
    include_examples 'authorization required' do
      let(:http_request) { get :edit }
    end
  end

  describe 'PATCH update' do
    include_examples 'authorization required' do
      let(:http_request) { patch :update, params: { content_block: { data: 'foobar' } } }
    end
  end
end
