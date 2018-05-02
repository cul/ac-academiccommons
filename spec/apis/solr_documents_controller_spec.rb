require 'rails_helper'

describe SolrDocumentsController, type: :controller, integration: true do
  before do
    @original_creds = Rails.application.secrets.index_api_key
    Rails.application.secrets.index_api_key = 'goodtoken'
    request.env['HTTP_AUTHORIZATION'] = api_key
    allow(controller).to receive(:notify_authors_of_new_item)
  end
  after do
    Rails.application.secrets.index_api_key = @original_creds
  end

  let(:api_key) do
    key = Rails.application.secrets.index_api_key
    ActionController::HttpAuthentication::Token.encode_credentials(key)
  end

  describe 'update' do
    before do
      delete :destroy, params: { id: 'actest:1' } # delete a fixture from the index so that the test is meaningful
    end
    it do
      get :show, params: { id: 'actest:1', format: 'json' }
      expect(response.status).to be 404
      put :update, params: { id: 'actest:1' }
      sleep(20) # It may take the solr document up to 15 sec to show up
      expect(response.status).to be 200
      expect(response.headers['Location']).to eql('http://test.host/doi/10.7916/ALICE')
      get :show, params: { id: 'actest:1', format: 'json' }
      expect(response.status).to be 200
      # publish does not cascade
      get :show, params: { id: 'actest:2', format: 'json' }
      expect(response.status).to be 404
      put :update, params: { id: 'actest:2' }
      ActiveFedora::SolrService.commit # Force commit, since we are not using softCommit
      expect(response.headers['Location']).to eql('http://test.host/doi/10.7916/TESTDOC2/download')
    end
    after do
      put :update, params: { id: 'actest:1' }
      put :update, params: { id: 'actest:2' }
      put :update, params: { id: 'actest:4' }
      ActiveFedora::SolrService.commit # Force commit, since we are not using softCommit
    end
  end
  describe 'destroy' do
    it do
      get :show, params: { id: 'actest:1', format: 'json' }
      expect(response.status).to be 200
      delete :destroy, params: { id: 'actest:1' }
      expect(response.status).to be 200
      get :show, params: { id: 'actest:1', format: 'json' }
      expect(response.status).to be 404
      # unpublish cascades
      get :show, params: { id: 'actest:2', format: 'json' }
      expect(response.status).to be 404
    end
    after do
      # reindex the fixture so that other tests can run
      put :update, params: { id: 'actest:1' }
      put :update, params: { id: 'actest:2' }
      put :update, params: { id: 'actest:4' }
      ActiveFedora::SolrService.commit # Force commit, since we are not using softCommit
    end
  end
end
