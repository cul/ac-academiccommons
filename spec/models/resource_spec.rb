require 'rails_helper'

describe Resource do
  let(:resource) do
    resource = Resource.new(pid: 'test:resource')
    resource.state = 'A'
    downloadable = resource.create_datastream(
      ActiveFedora::Datastream, 'content', dsLabel: 'foo.pdf', mimeType: 'application/pdf'
    )
    access = resource.create_datastream(
      ActiveFedora::Datastream, 'access', dsLabel: 'access.pdf', mimeType: 'application/pdf',
                                          controlGroup: 'E', dsLocation: 'file:/example/example/access.pdf'
    )
    resource.add_datastream(downloadable)
    resource.add_datastream(access)
    resource.datastreams['DC'].content = <<~XML.chomp
      <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
        <dc:type>Text</dc:type>
      </oai_dc:dc>
    XML

    allow(resource).to receive(:save)
    resource
  end

  context 'has content datastream' do
    describe '#to_solr' do
      subject { resource.to_solr }

      it { is_expected.to include('object_state_ssi' => 'A') } # from ActiveFedora
      it { is_expected.to include('dc_type_ssm' => ['Text']) }
      it { is_expected.to include('downloadable_content_type_ssi' => 'application/pdf') }
      it { is_expected.to include('downloadable_content_dsid_ssi' => 'content') }
      it { is_expected.to include('downloadable_content_label_ss' => 'foo.pdf') }
      it { is_expected.to include('access_copy_location_ssi' => 'file:/example/example/access.pdf') }
      context "['datastreams_ssim']" do
        subject { (resource.to_solr['datastreams_ssim'] || []).sort }

        it { is_expected.to eql(['DC', 'RELS-EXT', 'access', 'content']) }
      end
    end
  end
end
