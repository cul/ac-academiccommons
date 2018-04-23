require 'rails_helper'

describe Admin::IndexingController, type: :controller do

  describe 'GET show' do
    include_examples 'authorization required' do
      let(:http_request) { get :show }
    end
  end

  describe 'GET log_monitor' do
    include_context 'log'

    include_examples 'authorization required' do
      let(:http_request) { get :log_monitor, params: { timestamp: id } }
    end
  end
end
