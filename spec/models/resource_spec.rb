require 'rails_helper'

describe Resource do
  let(:resource) do
    resource = Resource.new(pid: 'test:resource')
    resource.state = 'A'
    downloadable = resource.create_datastream(
      ActiveFedora::Datastream, downloadable_dsid, dsLabel: 'foo.pdf', mimeType: 'application/pdf'
    )
    resource.add_datastream(downloadable)
    allow(resource).to receive(:save)
    resource
  end

  context 'has CONTENT datastream' do
    let(:downloadable_dsid) { 'CONTENT' }
    describe 'to_solr' do
      subject { resource.to_solr }
      it { is_expected.to include('object_state_ssi' => 'A') } # from ActiveFedora
      it { is_expected.to include('downloadable_content_type_ssi' => 'application/pdf') }
      it { is_expected.to include('downloadable_content_dsid_ssi' => downloadable_dsid) }
      it { is_expected.to include('downloadable_content_label_ss' => 'foo.pdf') }
    end
  end
end
