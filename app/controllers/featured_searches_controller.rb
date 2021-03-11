# frozen_string_literal: true
class FeaturedSearchesController < ApplicationController
  before_action :load_feature

  def show
    if @feature
      redirect_to controller: 'catalog', action: :index, f: { @feature.feature_category.field_name => [@feature.filter_value] }
    else
      render status: :not_found, plain: "feature '#{params[:slug]}' not found"
    end
  end

  def load_feature
    @feature = FeaturedSearch.find_by(slug: params[:slug])
  end
end
