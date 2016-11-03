require 'rails_helper'

describe SolrDocumentsController, :type => [:controller,:integration] do
  before do
    @original_creds = Rails.application.secrets.index_api_creds
    Rails.application.secrets.index_api_creds = {'name' => 'clientapp', 'password' =>'goodtoken'}
    request.env['HTTP_AUTHORIZATION'] = credentials
  end
  after do
    Rails.application.secrets.index_api_creds = @original_creds
  end
  let(:credentials) do
    user = Rails.application.secrets.index_api_creds['name']
    pw = Rails.application.secrets.index_api_creds['password']
    ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
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
      get :show, id: 'actest:1', format: 'json'
      expect(response.status).to eql(200)
      # publish does not cascade
      get :show, id: 'actest:2', format: 'json'
      expect(response.status).to eql(404)
    end
    after do
      put :update, { id: 'actest:1' }
      put :update, { id: 'actest:2' }
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
    end
  end
end
