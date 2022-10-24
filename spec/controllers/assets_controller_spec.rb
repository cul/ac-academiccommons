require 'rails_helper'

RSpec.describe AssetsController, type: :controller do
  describe 'GET legacy_fedora_content' do
    let(:resource_params) { { qt: 'search', fq: ['fedora3_pid_ssi:"good:id"', 'has_model_ssim:("info:fedora/ldpd:GenericResource" OR "info:fedora/ldpd:Resource")'], rows: 1 } }
    let(:mock_resource) do
      double(docs: [SolrDocument.new(id: '10.7616/TESTTEST', object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id'])])
    end

    before do
      allow(Blacklight.default_index).to receive(:search).with(resource_params).and_return(mock_resource)
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

  describe 'GET download' do
    let(:resource_doc)  { SolrDocument.new(id: '10.7616/TESTTEST', object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id']) }
    let(:parent_doc)    { SolrDocument.new(object_state_ssi: 'A') }
    let(:mock_resource) { double(docs: [resource_doc]) }
    let(:mock_parent)   { double(docs: [parent_doc]) }
    let(:mock_head_response) { double('headers', code: 200) }
    let(:resource_params) { { qt: 'search', fq: ['id:"10.7616/TESTTEST"', 'has_model_ssim:("info:fedora/ldpd:GenericResource" OR "info:fedora/ldpd:Resource")'], rows: 1 } }
    let(:parent_params)   { { qt: 'search', fq: ['fedora3_pid_ssi:(parent\:id)'], rows: 100_000 } }

    before do
      allow(Blacklight.default_index).to receive(:search).with(resource_params).and_return(mock_resource)
      allow(Blacklight.default_index).to receive(:search).with(parent_params).and_return(mock_parent)
      allow(HTTP).to receive(:head).and_return(mock_head_response)

      get :download, params: { id: '10.7616/TESTTEST' }
    end

    context 'when resource is active, parent is active' do
      let(:resource_doc) { SolrDocument.new(fedora3_pid_ssi: 'good:id', object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id']) }
      let(:parent_doc) { SolrDocument.new(object_state_ssi: 'A') }

      it 'returns correct X-Accel-Redirect header' do
        expect(response.headers['X-Accel-Redirect']).to eql('/repository_download/localhost:9090/fedora/objects/good:id/datastreams/content/content')
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
  describe 'GET captions' do
    let(:resource_doc)  { SolrDocument.new(id: '10.7616/TESTTEST', object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id'], datastreams_ssim: ['content', 'captions']) }
    let(:parent_doc)    { SolrDocument.new(object_state_ssi: 'A') }
    let(:mock_resource) { double(docs: [resource_doc]) }
    let(:mock_parent)   { double(docs: [parent_doc]) }
    let(:mock_head_response) { double('headers', code: 200) }
    let(:resource_params) { { qt: 'search', fq: ['id:"10.7616/TESTTEST"', 'has_model_ssim:("info:fedora/ldpd:GenericResource" OR "info:fedora/ldpd:Resource")'], rows: 1 } }
    let(:parent_params)   { { qt: 'search', fq: ['fedora3_pid_ssi:(parent\:id)'], rows: 100_000 } }

    before do
      allow(Blacklight.default_index).to receive(:search).with(resource_params).and_return(mock_resource)
      allow(Blacklight.default_index).to receive(:search).with(parent_params).and_return(mock_parent)
      allow(HTTP).to receive(:head).and_return(mock_head_response)

      get :captions, params: { id: '10.7616/TESTTEST' }
    end

    context 'when resource is active, parent is active' do
      let(:resource_doc) { SolrDocument.new(fedora3_pid_ssi: 'good:id', object_state_ssi: 'A', cul_member_of_ssim: ['info:fedora/parent:id'], datastreams_ssim: ['content', 'captions']) }
      let(:parent_doc) { SolrDocument.new(object_state_ssi: 'A') }

      it 'returns correct X-Accel-Redirect header' do
        expect(response.headers['X-Accel-Redirect']).to eql('/repository_download/localhost:9090/fedora/objects/good:id/datastreams/captions/content?captions.vtt')
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
