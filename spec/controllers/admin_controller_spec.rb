require 'rails_helper'

describe AdminController, type: :controller do
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

  describe 'GET agreements' do
    include_examples 'authorization required' do
      let(:http_request) { get :agreements }
    end
  end
end
