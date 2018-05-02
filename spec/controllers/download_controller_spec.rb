require 'rails_helper'

RSpec.describe DownloadController, type: :controller do
  describe 'GET download_log' do
    include_context 'log'

    include_examples 'authorization required' do
      let(:http_request) { get :download_log, params: { log_folder: 'ac-indexing', id: id } }
    end
  end

  describe 'GET legacy_fedora_content' do
    let(:mock_resource) do
      double(docs: [SolrDocument.new(id: '10.7616/TESTTEST', object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id'])])
    end

    before do
      allow(Blacklight.default_index).to receive(:search).and_return(mock_resource)
    end

    it 'redirects to /doi/:doi/download when datastream content' do
      get :legacy_fedora_content, params: { uri: 'good:id', block: 'content', filename: 'foot.txt' }
      expect(response).to redirect_to '/doi/10.7616/TESTTEST/download'
    end

    it 'redirects to /doi/:doi/download when datastream CONTENT' do
      get :legacy_fedora_content, params: { uri: 'good:id', block: 'CONTENT', filename: 'foot.txt' }
      expect(response).to redirect_to '/doi/10.7616/TESTTEST/download'
    end
  end

  describe 'GET content' do
    let(:resource_doc)  { SolrDocument.new(id: '10.7616/TESTTEST', object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id']) }
    let(:parent_doc)    { SolrDocument.new(object_state_ssi: 'A') }
    let(:mock_resource) { double(docs: [resource_doc]) }
    let(:mock_parent)   { double(docs: [parent_doc]) }
    let(:mock_client)   { double(HTTPClient, head: mock_head_response) }
    let(:mock_head_response) { double('headers', status: 200) }

    before do
      allow(Blacklight.default_index).to receive(:search).and_return(mock_resource, mock_parent)
      controller.instance_variable_set(:@cl, mock_client)

      get :content, params: { id: '10.7616/TESTTEST' }
    end

    context 'when resource is active, parent is active' do
      let(:resource_doc) { SolrDocument.new(fedora3_pid_ssi: 'good:id', object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id']) }
      let(:parent_doc) { SolrDocument.new(object_state_ssi: 'A') }

      it 'returns correct X-Accel-Redirect header' do
        expect(response.headers['X-Accel-Redirect']).to eql('/repository_download/localhost:8983/fedora/objects/good:id/datastreams/content/content')
      end
    end

    context 'when resource is inactive, parent is active' do
      let(:resource_doc) { SolrDocument.new(object_state_ssi: 'I', cul_member_of_ssim: ['info:fedora/parent:id']) }
      let(:parent_doc) { SolrDocument.new(object_state_ssi: 'A') }

      it 'returns empty X-Accel-Redirect header' do
        expect(response.headers['X-Accel-Redirect']).to be_nil
      end
    end

    context 'when resource is active, parent is inactive' do
      let(:resource_doc) { SolrDocument.new(object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id']) }
      let(:parent_doc) { SolrDocument.new(object_state_ssi: 'I') }

      it 'returns empty X-Accel-Redirect header' do
        expect(response.headers['X-Accel-Redirect']).to be_nil
      end
    end

    context 'when resource is active, parent is absent' do
      let(:resource_doc) { SolrDocument.new(object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id']) }
      let(:parent_doc) { SolrDocument.new }

      it 'returns empty X-Accel-Redirect header' do
        expect(response.headers['X-Accel-Redirect']).to be_nil
      end
    end
  end
end
