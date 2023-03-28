# frozen_string_literal: true

require 'rails_helper'

describe CatalogController, type: :controller do
  describe 'search_builder' do
    context 'when featured search requested' do
      subject(:solr_params) { search_builder.with(user_params).processed_parameters }

      let(:builder_context) { controller }
      let(:featured_search) { FactoryBot.create(:libraries_featured_search) }
      let(:featured_search_value) { featured_search.featured_search_values.first }
      let(:search_builder) { search_service.search_builder }
      let(:search_service) { controller.search_service }
      let(:user_params) { { f: { featured_search: [featured_search.slug] } } }

      it 'includes featured search filters' do
        expect(solr_params[:fq]).to include('department_ssim:("Libraries")')
      end
    end
  end
end
