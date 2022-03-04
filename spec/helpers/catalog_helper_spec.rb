# frozen_string_literal: true

require 'rails_helper'

describe CatalogHelper, type: :helper do
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:featured_search) { FactoryBot.create(:libraries_featured_search) }
  let(:field_name) { featured_search.feature_category.field_name }

  before do
    allow(helper).to receive(:params).and_return(params)
  end
  describe 'exclusive_feature_search?' do
    let(:params) { parameter_class.new(f: { featured_search: [featured_search.slug] }) }
    it { expect(helper.exclusive_feature_search?(featured_search)).to be true }
    context "there is a query param" do
      let(:params) { parameter_class.new(q: 'hello', f: { featured_search: [featured_search.slug] }) }
      it { expect(helper.exclusive_feature_search?(featured_search)).to be false }
    end
    context "there are multiple filters" do
      let(:params) { parameter_class.new(f: { hello: ['moto'], featured_search: [featured_search.slug] }) }
      it { expect(helper.exclusive_feature_search?(featured_search)).to be false }
    end
  end
end
