require 'rails_helper'

describe SolrDocument do
  describe '#download_path' do
    let(:document) do
      described_class.new(
        'id' => '10.7916/TESTDOC2',
        'active_fedora_model_ssi' => 'GenericResource'
      )
    end

    it 'generates correct download_path' do
      expect(document.download_path).to eql '/doi/10.7916/TESTDOC2/download'
    end
  end

  describe '#assets' do
    let(:document) do
      described_class.new(
        id: 'test:obj', fedora3_pid_ssi: 'test:obj', object_state_ssi: 'A',
        free_to_read_start_date_ssi: Date.current.strftime('%Y-%m-%d')
      )
    end

    let(:empty_response) { { 'response' => { 'docs' => [] } } }

    context 'defaults to non-active exclusion' do
      let(:expected_params) do
        {
          qt: 'search',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:fedora3_pid_ssi]}\"", 'object_state_ssi:"A"'],
          rows: 100_000, facet: false
        }
      end

      let(:solr_response) do
        Blacklight::Solr::Response.new(
          {
            'response' => {
              'docs' => [
                {
                  'id' => 'actest:2',
                  'fedora3_pid_ssi' => 'actest:2',
                  'active_fedora_model_ssi' => 'GenericResource',
                  'downloadable_content_type_ssi' => 'application/pdf',
                  'downloadable_content_dsid_ssi' => 'CONTENT',
                  'downloadable_content_label_ss' => 'alice_in_wonderland.pdf'
                },
                {
                  'id' => 'actest:10',
                  'fedora3_pid_ssi' => 'actest:10',
                  'active_fedora_model_ssi' => 'GenericResource',
                  'downloadable_content_type_ssi' => 'image/png',
                  'downloadable_content_dsid_ssi' => 'CONTENT',
                  'downloadable_content_label_ss' => 'alice_in_wonderland_cover.png'
                }
              ]
            }
          }, {}
        )
      end

      before do
        allow(Blacklight.default_index).to receive(:search)
          .with(expected_params)
          .and_return(solr_response)
          .once
      end

      it 'calls solr with expected params' do
        expect(document.assets.count).to eq 2
      end

      it 'returns asset documents with thumbnail urls' do
        expect(document.assets.map { |a| a[:id] }).to match_array ['actest:2', 'actest:10']
        non_urls = document.assets.map(&:thumbnail).detect { |val| val !~ %r{http:\/\/.*jpg} }
        expect(non_urls).to be_falsey
      end
    end

    context 'parent doc is embargoed' do
      let(:document) do
        described_class.new(
          id: 'test:obj',
          free_to_read_start_date_ssi: Date.tomorrow.strftime('%Y-%m-%d'),
          object_state_ssi: 'A'
        )
      end

      it 'calls solr with expected params' do
        expect(Blacklight.default_index).not_to receive(:search)
        document.assets
      end
    end

    context 'parent doc is inactive' do
      let(:document) do
        described_class.new(
          id: 'test:obj',
          free_to_read_start_date_ssi: Date.current.prev_day.strftime('%Y-%m-%d'),
          object_state_ssi: 'I'
        )
      end

      it 'calls solr with expected params' do
        expect(Blacklight.default_index).not_to receive(:search)
        document.assets
      end
    end

    context 'parent doc was embargoed' do
      let(:document) do
        described_class.new(
          id: 'test:obj', fedora3_pid_ssi: 'test:obj',
          free_to_read_start_date_ssi: Date.current.prev_day.strftime('%Y-%m-%d'),
          object_state_ssi: 'A'
        )
      end

      let(:expected_params) do
        {
          qt: 'search',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:fedora3_pid_ssi]}\"", 'object_state_ssi:"A"'],
          facet: false, rows: 100_000
        }
      end

      it 'calls solr with expected params' do
        expect(Blacklight.default_index).to receive(:search)
          .with(expected_params)
          .and_return(:empty_response)
        document.assets
      end
    end

    context 'when assets are already included in solr response' do
      let(:document) do
        described_class.new(
          id: 'test:obj', fedora3_pid_ssi: 'test:obj', object_state_ssi: 'A',
          free_to_read_start_date_ssi: Date.current.strftime('%Y-%m-%d'),
          assets: {
            numFound: 1, start: 0, docs: [
              {
                object_state_ssi: 'A',
                active_fedora_model_ssi: 'GenericResource',
                id: 'test:asset',
                rdf_type_ssim: ['http://purl.oclc.org/NET/CUL/Resource'],
                cc_license_ssim: ['info:fedora/'],
                has_model_ssim: ['info:fedora/ldpd:GenericResource'],
                pid: 'test:asset',
                fedora3_pid_ssi: 'test:asset'
              }
            ]
          }
        )
      end

      it 'does not query solr' do
        expect(Blacklight.default_index).not_to receive(:search).with(any_args)
        document.assets
      end

      it 'returns assets' do
        expect(document.assets.first.id).to eql 'test:asset'
      end
    end
  end
end
