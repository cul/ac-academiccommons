require 'rails_helper'

describe SolrDocumentsController, type: :controller, integration: true do
  let(:api_key) { 'goodtoken' }
  let(:encoded_api_key) { ActionController::HttpAuthentication::Token.encode_credentials(api_key) }

  before do
    allow(Rails.application.secrets).to receive(:index_api_key).and_return(api_key)
    request.env['HTTP_AUTHORIZATION'] = encoded_api_key
    allow(controller).to receive(:notify_authors_of_new_item)
  end

  describe 'update' do
    before do
      delete :destroy, params: { id: 'actest:1' } # delete a fixture from the index so that the test is meaningful
    end

    after do
      index = AcademicCommons::Indexer.new
      index.items('actest:1', only_in_solr: false)
      index.close
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
      ActiveFedora::SolrService.commit # Force commit, since we are using softCommit
      expect(response.headers['Location']).to eql('http://test.host/doi/10.7916/TESTDOC2/download')
    end
  end

  describe 'destroy' do
    after do
      # reindex the item fixture and its assets so that other tests can run
      index = AcademicCommons::Indexer.new
      index.items('actest:1', only_in_solr: false)
      index.close
    end

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
  end
end
