require "rails_helper"

describe CatalogHelper do
  describe "#build_resource_list" do
    let(:document) do
      SolrDocument.new({
        id: 'test:obj',
        free_to_read_start_date: Date.today.strftime('%Y-%m-%d'),
        object_state_ssi: 'A'
      })
    end
    let(:empty_response) { { 'response' => { 'docs' => [] } } }
    context "defaults to non-active exclusion" do
      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\"", "object_state_ssi:A"],
          rows: 10000, facet: false
        }
      end
      let(:solr_response) do
        {
          'response' => {
            'docs' => [
              {
                'id' =>'actest:2', 'pid' =>'actest:2',
                'downloadable_content_type_ssi' => 'application/pdf',
                'downloadable_content_dsid_ssi' => 'CONTENT',
                'downloadable_content_label_ss' => 'alice_in_wonderland.pdf',
              },
              {
                'id' =>'actest:10', 'pid' =>'actest:10',
                'downloadable_content_type_ssi' => 'image/png',
                'downloadable_content_dsid_ssi' => 'CONTENT',
                'downloadable_content_label_ss' => 'alice_in_wonderland_cover.png',
              }
            ]
          }
        }
      end
      it "calls solr with expected params" do
        expect(Blacklight.default_index.connection).to receive(:get).
          with('select', { params: expected_params }).
          and_return(empty_response)
        helper.build_resource_list(document)
      end
      it 'returns array with documents' do
        allow(Blacklight.default_index.connection).to receive(:get)
          .with('select', params: expected_params)
          .and_return(solr_response)
        resource_list = helper.build_resource_list(document)
        expect(resource_list.count).to eq 2
        expect(resource_list).to contain_exactly(
          { pid: 'actest:2', filename: 'alice_in_wonderland.pdf', content_type: 'application/pdf',
            download_path: '/download/fedora_content/download/actest:2/CONTENT/alice_in_wonderland.pdf' },
          { pid: 'actest:10', filename: 'alice_in_wonderland_cover.png', content_type: 'image/png',
            download_path: '/download/fedora_content/download/actest:10/CONTENT/alice_in_wonderland_cover.png' }
        )
      end
    end
    context "includes non-active" do
      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\""],
          rows: 10000, facet: false
        }
      end
      it "calls solr with expected params" do
        expect(Blacklight.default_index.connection).to receive(:get).
          with('select', { params: expected_params }).
          and_return(:empty_response)
        helper.build_resource_list(document, true)
      end
    end
    context "parent doc is embargoed" do
      let(:document) do
        SolrDocument.new({
          id: 'test:obj',
          free_to_read_start_date: Date.tomorrow.strftime('%Y-%m-%d'),
          object_state_ssi: 'A'
        })
      end
      it "calls solr with expected params" do
        expect(Blacklight.default_index.connection).not_to receive(:get)
        helper.build_resource_list(document, true)
      end
    end
    context "parent doc is inactive" do
      let(:document) do
        SolrDocument.new({
          id: 'test:obj',
          free_to_read_start_date: Date.today.prev_day.strftime('%Y-%m-%d'),
          object_state_ssi: 'I'
        })
      end
      it "calls solr with expected params" do
        expect(Blacklight.default_index.connection).not_to receive(:get)
        helper.build_resource_list(document, true)
      end
    end
    context "parent doc was embargoed" do
      let(:document) do
        SolrDocument.new({
          id: 'test:obj',
          free_to_read_start_date: Date.today.prev_day.strftime('%Y-%m-%d'),
          object_state_ssi: 'A'
        })
      end
      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\""],
          rows: 10000, facet: false
        }
      end
      it "calls solr with expected params" do
        expect(Blacklight.default_index.connection).to receive(:get).
          with('select', { params: expected_params }).
          and_return(:empty_response)
        helper.build_resource_list(document, true)
      end
    end
  end
end
