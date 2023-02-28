# frozen_string_literal: true

require 'rails_helper'
describe SearchBuilder, type: :model do
  context 'when search params contain non-configured sort parameter' do
    let(:search_builder) { described_class.new processor_chain, scope }
    let(:processor_chain) { [] }
    let(:blacklight_config) { Blacklight::Configuration.new }
    let(:scope) { instance_double("CatalogController", blacklight_config: blacklight_config) }
    let(:search_params) {}
    before do
      blacklight_config[:sort_fields] = { "Best Match" => "" }
      search_builder.blacklight_params['sort'] = "Fake Sort Param"
      search_builder.validate_sort(search_params)
    end

    it 'deletes the sort parameter' do
      expect(search_builder.blacklight_params['sort']).to be nil
    end
  end
end
