require 'rails_helper'

describe SolrDocumentsController, type: :controller, integration: true do
  let(:api_key) { 'goodtoken' }
  let(:encoded_api_key) { ActionController::HttpAuthentication::Token.encode_credentials(api_key) }
  let(:mock_vector_embedding_value) do
    fixture_to_json('desc_metadata/mock_vector_embedding_value_string-research.json')
  end

  before do
    allow(EmbeddingService::Endpoint).to receive(:generate_vector_embedding).and_return(mock_vector_embedding_value)
    allow(Rails.application.credentials).to receive(:index_api_key).and_return(api_key)
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
      # Normally we'd have to wait a while for the solr document to be auto-commited,
      # but for this test we'll force an immediate commit so we don't need to wait.
      controller.rsolr.commit

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
