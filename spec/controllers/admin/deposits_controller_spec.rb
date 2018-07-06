require 'rails_helper'

describe Admin::DepositsController, type: :controller do
  let(:id) { 'foo' }

  shared_context 'mock_deposit' do
    let(:deposit) { double }

    before do
      allow(Deposit).to receive(:find).with(id).and_return(deposit)
    end
  end

  describe 'GET index' do
    include_examples 'authorization required' do
      let(:http_request) { get :index }
    end
  end

  describe 'GET show' do
    include_context 'mock_deposit'

    include_examples 'authorization required' do
      let(:http_request) { get :show, params: { id: id } }
    end
  end
end
