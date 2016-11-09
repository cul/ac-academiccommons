require 'rails_helper'

describe AdminController, :type => :controller do
  let(:id) { 'foo' }

  shared_context 'mock_deposit' do
    let(:this_file) { __FILE__.sub(Rails.root.to_s + '/','') }

    before do
      @deposit = double(Deposit)
      allow(Deposit).to receive(:find).with(id).and_return(@deposit)
      allow(@deposit).to receive(:file_path).and_return(this_file)
    end
  end

  describe 'GET index' do
    include_examples 'authorization required' do
      let(:http_request) { get :index }
    end
  end

  describe 'GET edit_alert_message' do
    include_examples 'authorization required' do
      let(:http_request) { get :edit_alert_message }
    end
  end

  describe 'POST edit_alert_message' do
    include_examples 'authorization required' do
      let(:http_request) { post :edit_alert_message }
    end
  end

  describe 'GET deposits' do
    include_examples 'authorization required' do
      let(:http_request) { get :deposits }
    end
  end

  describe 'GET agreements' do
    include_examples 'authorization required' do
      let(:http_request) { get :agreements }
    end
  end

  describe 'GET ingest' do
    include_examples 'authorization required' do
      let(:http_request) { get :ingest, id: 'foo' }
    end
  end

  describe 'GET show_deposit' do
    include_context 'mock_deposit'

    include_examples 'authorization required' do
      let(:http_request) { get :show_deposit, id: id }
    end
  end

  describe 'GET download_deposit_file' do
    include_context 'mock_deposit'

    include_examples 'authorization required' do
      let(:http_request) { get :download_deposit_file, id: id }
    end
  end
end
