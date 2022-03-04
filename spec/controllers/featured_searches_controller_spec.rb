# frozen_string_literal: true
require 'rails_helper'

describe FeaturedSearchesController, type: :controller do
  let(:featured_search) { FactoryBot.create(:libraries_featured_search) }
  let(:field_name) { featured_search.feature_category.field_name }
  let(:filter_param) { CGI.escape(featured_search.filter_value) }
  describe 'GET show' do
    before do
      get :show, params: { slug: slug }
    end
    context 'for an existing feature' do
      let(:slug) { featured_search.slug }
      it "redirects" do
        expect(response.status).to be(302)
      end
      it "sets Location header for catalog with a facet" do
        expect(response.header['Location']).to eql("http://test.host/search?f%5Bfeatured_search%5D%5B%5D=#{slug}")
      end
    end
    context 'for a non-existent feature' do
      let(:slug) { 'Axfgs2dThnj6' }
      it "returns a 404" do
        expect(response.status).to be(404)
      end
    end
  end
end
