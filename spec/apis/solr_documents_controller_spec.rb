require 'rails_helper'

describe SolrDocumentsController, type: :controller, integration: true do
  before do
    @original_creds = Rails.application.secrets.index_api_key
    Rails.application.secrets.index_api_key = 'goodtoken'
    request.env['HTTP_AUTHORIZATION'] = api_key
  end
  after do
    Rails.application.secrets.index_api_key = @original_creds
  end

  let(:api_key) do
    key = Rails.application.secrets.index_api_key
    ActionController::HttpAuthentication::Token.encode_credentials(key)
  end

  describe "update" do
    before do
      # delete a fixture from the index so that the test is meaningful
      delete :destroy, { id: 'actest:1' }
    end
    it do
      get :show, id: 'actest:1', format: 'json'
      expect(response.status).to eql(404)
      put :update, { id: 'actest:1' }
      expect(response.status).to eql(200)
      expect(response.headers['Location']).to eql("http://test.host/catalog/actest:1")
      get :show, id: 'actest:1', format: 'json'
      expect(response.status).to eql(200)
      # publish does not cascade
      get :show, id: 'actest:2', format: 'json'
      expect(response.status).to eql(404)
      put :update, { id: 'actest:2' }
      expect(response.headers['Location']).
        to eql("http://test.host/download/fedora_content/download/actest:2/CONTENT/alice_in_wonderland.pdf")
    end
    after do
      put :update, { id: 'actest:1' }
      put :update, { id: 'actest:2' }
      put :update, { id: 'actest:4' }
    end
  end
  describe "destroy" do
    it do
      get :show, id: 'actest:1', format: 'json'
      expect(response.status).to eql(200)
      delete :destroy, { id: 'actest:1' }
      expect(response.status).to eql(200)
      get :show, id: 'actest:1', format: 'json'
      expect(response.status).to eql(404)
      # unpublish cascades
      get :show, id: 'actest:2', format: 'json'
      expect(response.status).to eql(404)
    end
    after do
      # reindex the fixture so that other tests can run
      put :update, { id: 'actest:1' }
      put :update, { id: 'actest:2' }
      put :update, { id: 'actest:4' }
    end
  end
end
