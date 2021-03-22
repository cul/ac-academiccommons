# frozen_string_literal: true
require 'rails_helper'

describe AcademicCommons::FeaturedSearches do
  let(:featured_search) { FactoryBot.create(:libraries_featured_search) }
  let(:featured_search_value) { featured_search.featured_search_values.first }
  let(:num_docs) { described_class::MINIMUM_DOC_COUNT }
  let(:facet_field) { featured_search.feature_category.field_name }
  let(:facet_hits) { num_docs }
  let(:facet_item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: featured_search_value.value, hits: facet_hits) }
  let(:facet) { Blacklight::Solr::Response::Facets::FacetField.new(facet_field, [facet_item]) }
  let(:solr_response) do
    sr = instance_double(Blacklight::Solr::Response)
    allow(sr).to receive(:total).and_return(num_docs)
    allow(sr).to receive(:aggregations).and_return(facet_field => facet)
    sr
  end
  describe '.for' do
    it "finds the feature" do
      expect(described_class.for(solr_response).to_a).to eql([featured_search])
    end
    context "matches do not meet the threshold" do
      let(:num_docs) { 100 }
      let(:facet_hits) { (featured_search.feature_category.threshold / 100) * (num_docs - 1) }
      it "returns an empty array" do
        expect(described_class.for(solr_response).to_a).to be_empty
      end
    end
    context "result set does not meet size requirement" do
      let(:num_docs) { described_class::MINIMUM_DOC_COUNT - 1 }
      it "returns an empty array" do
        expect(described_class.for(solr_response).to_a).to be_empty
      end
    end
    context "response is nil" do
      let(:solr_response) { nil }
      it "returns an empty array" do
        expect(described_class.for(solr_response).to_a).to be_empty
      end
    end
  end
end
