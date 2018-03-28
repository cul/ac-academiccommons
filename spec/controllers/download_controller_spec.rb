require 'rails_helper'

RSpec.describe DownloadController, type: :controller do
  describe 'GET download_log' do
    include_context 'log'

    include_examples 'authorization required' do
      let(:http_request) { get :download_log, log_folder: 'ac-indexing', id: id }
    end
  end

  describe 'GET fedora_content' do
    let(:mock_client) { double(HTTPClient, head: mock_head_response)}
    let(:mock_head_response) { double('headers', status: 200) }
    let(:mock_solr) { double('Solr') }

    before do
      allow(Blacklight.default_index).to receive(:connection).and_return(mock_solr)
      controller.instance_variable_set(:@cl, mock_client)
    end

    context 'when downloading resource' do
      before do
        allow(mock_solr).to receive(:get).and_return({'response' => {'docs' => [mock_resource]}}, {'response' => {'docs' => [mock_parent].compact}})
        get :fedora_content, uri: 'good:id', block: 'content', filename: 'foot.txt', download_method: 'download'
      end
      context 'resource is active, parent is active' do
        let(:mock_resource) { SolrDocument.new(object_state_ssi: 'A', cul_member_of_ssim: ['parent:id']) }
        let(:mock_parent) { SolrDocument.new(object_state_ssi: 'A') }
        # it should work
        it do
          expect(response.headers['X-Accel-Redirect']).to eql('/repository_download/localhost:8983/fedora/objects/good:id/datastreams/content/content')
        end
      end
      context 'resource is inactive, parent is active' do
        let(:mock_resource) { SolrDocument.new(object_state_ssi: 'I', cul_member_of_ssim: ['parent:id']) }
        let(:mock_parent) { SolrDocument.new(object_state_ssi: 'A') }
        # it should fail
        it do
          expect(response.headers['X-Accel-Redirect']).to be_nil
        end
      end
      context 'resource is active, parent is inactive' do
        let(:mock_resource) { SolrDocument.new(object_state_ssi: 'A', cul_member_of_ssim: ['parent:id']) }
        let(:mock_parent) { SolrDocument.new(object_state_ssi: 'I') }
        # it should fail
        it do
          expect(response.headers['X-Accel-Redirect']).to be_nil
        end
      end
      context 'resource is active, parent is absent' do
        let(:mock_resource) { SolrDocument.new(object_state_ssi: 'A', cul_member_of_ssim: ['parent:id']) }
        let(:mock_parent) { nil }
        # it should fail
        it do
          expect(response.headers['X-Accel-Redirect']).to be_nil
        end
      end
      context 'resource is active, parent is not constituent of AC' do
        # it should fail
        #TODO: Implement this test when memberOf: collection3 is replaced with constituentOf
        pending 'migrations of relationships to Hyacinth standards'
      end
    end

    describe 'when retrieving metadata' do
      let(:response_body) { '<?xml version="1.0" encoding="ISO-8859-1"?>' }
      let(:mock_head_response) { double('headers', status: 200, header: { 'Content-Type' => 'text/xml' }) }
      let(:mock_client) { double(HTTPClient, head: mock_head_response, get_content: response_body)}

      before do
        allow(mock_solr).to receive(:get).and_return({'response' => {'docs' => [mock_resource]}})
      end

      context 'from active metadata resource' do
        context 'with solr document' do
          let(:mock_resource) { SolrDocument.new(object_state_ssi: 'A', has_model_ssim: ['info:fedora/ldpd:MODSMetadata']) }
          it 'returns metadata' do
            get :fedora_content, uri: 'good:id', block: 'CONTENT', filename: 'metadata.txt', download_method: 'show_pretty', data: 'meta'
            expect(response.headers['Content-Type']).to include 'text/plain'
          end
        end

        context 'without solr document' do
          before :each do
            allow(ActiveFedora::Base).to receive(:find).with('good:id').and_return(ActiveFedora::Base.new)
            allow(ActiveFedora::Base.find('good:id')).to receive(:to_solr).and_return({'has_model_ssim' => 'info:fedora/ldpd:MODSMetadata'})
          end

          let(:mock_resource) { nil }
          it 'returns metadata' do
            get :fedora_content, uri: 'good:id', block: 'CONTENT', filename: 'metadata.txt', download_method: 'show_pretty', data: 'meta'
            expect(response.headers['Content-Type']).to include 'text/plain'
          end
        end
      end

      context 'from inactive metadata resource' do
        let(:mock_resource) { SolrDocument.new(object_state_ssi: 'I', has_model_ssim: ['info:fedora/ldpd:MODSMetadata']) }
        it 'returns metadata' do
          get :fedora_content, uri: 'good:id', block: 'CONTENT', filename: 'metadata.txt', download_method: 'show_pretty', data: 'meta'
          expect(response.headers['Content-Type']).to include 'text/plain'
        end
      end

      context 'from active parentless object' do
        let(:mock_resource) { SolrDocument.new(object_state_ssi: 'A') }
        it 'returns metadata' do
          get :fedora_content, uri: 'good:id', block: 'descMetadata', filename: 'metadata.txt', download_method: 'show_pretty', data: 'meta'
          expect(response.headers['Content-Type']).to eql 'text/plain'
        end
      end

      context 'from inactive parentless object' do
        let(:mock_resource) { SolrDocument.new(object_state_ssi: 'I') }
        it 'returns metadata' do
          get :fedora_content, uri: 'good:id', block: 'descMetadata', filename: 'metadata.txt', download_method: 'show_pretty', data: 'meta'
          expect(response.headers['Content-Type']).to eql 'text/plain'
        end
      end
    end
  end
end
