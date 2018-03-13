require 'rails_helper'

describe SolrDocument do
  describe '#download_path' do
    let(:document) do
      described_class.new(
        'id' => 'actest:2', 'pid' => 'actest:2',
        'active_fedora_model_ssi' => 'GenericResource',
        'downloadable_content_type_ssi' => 'application/pdf',
        'downloadable_content_dsid_ssi' => 'CONTENT',
        'downloadable_content_label_ss' => 'alice_in_wonderland.pdf'
      )
    end

    it 'generates correct download_path' do
      expect(document.download_path).to eql '/download/fedora_content/download/actest:2/CONTENT/alice_in_wonderland.pdf'
    end
  end

  describe '#assets' do
    let(:document) do
      described_class.new(
        id: 'test:obj', object_state_ssi: 'A',
        free_to_read_start_date: Date.current.strftime('%Y-%m-%d')
      )
    end

    let(:empty_response) { { 'response' => { 'docs' => [] } } }

    context 'defaults to non-active exclusion' do
      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\"", 'object_state_ssi:A'],
          rows: 10_000, facet: false
        }
      end

      let(:solr_response) do
        {
          'response' => {
            'docs' => [
              {
                'id' => 'actest:2',
                'downloadable_content_type_ssi' => 'application/pdf',
                'downloadable_content_dsid_ssi' => 'CONTENT',
                'downloadable_content_label_ss' => 'alice_in_wonderland.pdf'
              },
              {
                'id' => 'actest:10',
                'downloadable_content_type_ssi' => 'image/png',
                'downloadable_content_dsid_ssi' => 'CONTENT',
                'downloadable_content_label_ss' => 'alice_in_wonderland_cover.png'
              }
            ]
          }
        }
      end

      it 'calls solr with expected params' do
        expect(Blacklight.default_index.connection).to receive(:get)
          .with('select', params: expected_params)
          .and_return(empty_response)
        document.assets
      end

      it 'returns array with documents' do
        allow(Blacklight.default_index.connection).to receive(:get)
          .with('select', params: expected_params)
          .and_return(solr_response)
        expect(document.assets.count).to eq 2
        expect(document.assets.map(&:id)).to match_array ['actest:2', 'actest:10']
      end
    end

    context 'includes non-active' do
      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\""],
          rows: 10_000, facet: false
        }
      end

      it 'calls solr with expected params' do
        expect(Blacklight.default_index.connection).to receive(:get)
          .with('select', params: expected_params)
          .and_return(:empty_response)
        document.assets(include_inactive: true)
      end
    end

    context 'parent doc is embargoed' do
      let(:document) do
        described_class.new(
          id: 'test:obj',
          free_to_read_start_date: Date.tomorrow.strftime('%Y-%m-%d'),
          object_state_ssi: 'A'
        )
      end

      it 'calls solr with expected params' do
        expect(Blacklight.default_index.connection).not_to receive(:get)
        document.assets(include_inactive: true)
      end
    end

    context 'parent doc is inactive' do
      let(:document) do
        described_class.new(
          id: 'test:obj',
          free_to_read_start_date: Date.current.prev_day.strftime('%Y-%m-%d'),
          object_state_ssi: 'I'
        )
      end

      it 'calls solr with expected params' do
        expect(Blacklight.default_index.connection).not_to receive(:get)
        document.assets(include_inactive: true)
      end
    end

    context 'parent doc was embargoed' do
      let(:document) do
        described_class.new(
          id: 'test:obj',
          free_to_read_start_date: Date.current.prev_day.strftime('%Y-%m-%d'),
          object_state_ssi: 'A'
        )
      end

      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\""],
          rows: 10_000, facet: false
        }
      end

      it 'calls solr with expected params' do
        expect(Blacklight.default_index.connection).to receive(:get)
          .with('select', params: expected_params)
          .and_return(:empty_response)
        document.assets(include_inactive: true)
      end
    end
  end
end
