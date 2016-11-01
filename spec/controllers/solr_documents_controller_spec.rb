require 'rails_helper'

describe SolrDocumentsController, :type => :controller do
  before do
    @original_creds = Rails.application.secrets.index_api_creds
    Rails.application.secrets.index_api_creds = {'name' => 'clientapp', 'password' =>'goodtoken'}
    request.env['HTTP_AUTHORIZATION'] = credentials
    allow(ActiveFedora::Base).to receive(:find).with('baad:id').and_raise(ActiveFedora::ObjectNotFoundError)
  end
  after do
    Rails.application.secrets.index_api_creds = @original_creds
  end
  let(:mock_object) do
    double(ActiveFedora::Base)
  end
  describe '#update' do
    subject do
      put :update, params
      response.status
    end
    context 'no credentials' do
      let(:credentials) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid credentials' do
      let(:credentials) do
        user = Rails.application.secrets.index_api_creds['name']
        pw = 'badtoken'
        ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
      end
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid credentials' do
      let(:credentials) do
        user = Rails.application.secrets.index_api_creds['name']
        pw = Rails.application.secrets.index_api_creds['password']
        ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
      end
      context 'bad doc id' do
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(404) }
      end
      context 'good doc id' do
        let(:mock_object) do
          double(ActiveFedora::Base)
        end
        let(:params) { { id: 'good:id' } }
        before do
          allow(ActiveFedora::Base).to receive(:find).with('good:id').and_return(mock_object)
          expect(mock_object).to receive(:update_index)
        end
        it do
          expect(subject).to eql(200)
        end
      end
    end
  end
  describe '#destroy' do
    let(:rsolr) { double('RSolr') }
    #TODO: Determine if RSolr signals a missing id on delete
    let(:bad_id_response) do
      {"responseHeader"=>{"status"=>0, "QTime"=>41}}
    end
    let(:good_id_response) do
      {"responseHeader"=>{"status"=>0, "QTime"=>41}}
    end
    before do
      allow(controller).to receive(:rsolr).and_return(rsolr)
    end
    subject do
      delete :destroy, params
      response.status
    end
    context 'no credentials' do
      let(:credentials) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid credentials' do
      let(:credentials) do
        user = Rails.application.secrets.index_api_creds['name']
        pw = 'badtoken'
        ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
      end
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid credentials' do
      before do
        allow(rsolr).to receive(:delete_by_id).with('baad:id').and_return(bad_id_response)
        allow(rsolr).to receive(:delete_by_id).with('good:id').and_return(good_id_response)
        allow(rsolr).to receive(:commit)
      end
      let(:credentials) do
        user = Rails.application.secrets.index_api_creds['name']
        pw = Rails.application.secrets.index_api_creds['password']
        ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
      end
      context 'bad doc id' do
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(200) }
      end
      context 'good doc id' do
        let(:params) { { id: 'good:id' } }
        it { is_expected.to eql(200) }
      end
    end
  end
end
