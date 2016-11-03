require 'rails_helper'

describe IngestMonitorController, :type => :controller do
  describe 'GET show' do
    include_context 'log'

    include_examples 'authorization required' do
      let(:http_request) { get :show, :id => id }
    end
  end
end
