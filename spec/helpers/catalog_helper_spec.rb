require "rails_helper"

describe CatalogHelper do
  describe "#build_resource_list" do
    let(:document) { SolrDocument.new({ id: 'test:obj' }) }
    let(:empty_response) { { 'response' => { 'docs' => [] } } }
    context "defaults to non-active exclusion" do
      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\"", "object_state_ssi:A"],
          rows: 10000, facet: false
        }
      end
      it "calls solr with expected params" do
        expect(Blacklight.solr).to receive(:get).
          with('select', { params: expected_params }).
          and_return(:empty_response)
        helper.build_resource_list(document)
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
        expect(Blacklight.solr).to receive(:get).
          with('select', { params: expected_params }).
          and_return(:empty_response)
        helper.build_resource_list(document, true)
      end
    end
    context "parent doc is embargoed" do
      let(:document) { SolrDocument.new({ id: 'test:obj', free_to_read_start_date: Date.tomorrow.strftime('%Y-%m-%d') }) }
      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\""],
          rows: 10000, facet: false
        }
      end
      it "calls solr with expected params" do
        expect(Blacklight.solr).not_to receive(:get)
        helper.build_resource_list(document, true)
      end
    end
    context "parent doc was embargoed" do
      let(:document) { SolrDocument.new({ id: 'test:obj', free_to_read_start_date: Date.yesterday.strftime('%Y-%m-%d') }) }
      let(:expected_params) do
        {
          q: '*:*', qt: 'standard', fl: '*',
          fq: ["cul_member_of_ssim:\"info:fedora/#{document[:id]}\""],
          rows: 10000, facet: false
        }
      end
      it "calls solr with expected params" do
        expect(Blacklight.solr).to receive(:get).and_return(:empty_response)
        helper.build_resource_list(document, true)
      end
    end
  end
end