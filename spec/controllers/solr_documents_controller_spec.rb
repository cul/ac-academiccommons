require 'rails_helper'

describe SolrDocumentsController, :type => :controller do
  shared_context 'good api key' do
   let(:api_key) do
     key = Rails.application.secrets.index_api_key
     ActionController::HttpAuthentication::Token.encode_credentials(key)
   end
  end

  shared_context 'bad api key' do
    let(:api_key) do
      ActionController::HttpAuthentication::Token.encode_credentials('badtoken')
    end
  end

  before do
    @original_creds = Rails.application.secrets.index_api_key
    Rails.application.secrets.index_api_key = 'goodtoken'
    request.env['HTTP_AUTHORIZATION'] = api_key
    allow(ActiveFedora::Base).to receive(:find).with('baad:id').and_raise(ActiveFedora::ObjectNotFoundError)
  end

  after do
    Rails.application.secrets.index_api_key = @original_creds
  end

  let(:mock_object) do
    double(ActiveFedora::Base)
  end

  describe '#update' do
    subject do
      put :update, params
      response.status
    end
    context 'no api key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      include_context 'bad api key'

      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api key' do
      include_context 'good api key'
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
    context 'no api key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      include_context 'bad api key'
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api key' do
      include_context 'good api key'
      before do
        allow(rsolr).to receive(:delete_by_id).with('baad:id').and_return(bad_id_response)
        allow(rsolr).to receive(:delete_by_id).with('good:id').and_return(good_id_response)
        allow(rsolr).to receive(:commit)
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
