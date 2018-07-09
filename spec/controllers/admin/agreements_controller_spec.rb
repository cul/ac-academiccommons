require 'rails_helper'

describe Admin::AgreementsController, type: :controller do
  describe 'GET index' do
    include_examples 'authorization required' do
      let(:http_request) { get :index }
    end
  end
end
