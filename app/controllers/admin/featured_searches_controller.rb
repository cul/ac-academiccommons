# frozen_string_literal: true
module Admin
  class FeaturedSearchesController < AdminController
    load_and_authorize_resource

    def new
      @featured_search ||= FeaturedSearch.new
      @featured_search.featured_search_values.build
    end

    def edit
      @featured_search ||= FeaturedSearch.find(params[:id])
    end

    def create
      Rails.logger.debug 'why here?'
      Rails.logger.debug @featured_search
      @featured_search = FeaturedSearch.new(featured_search_params)
      if @featured_search.save
        flash[:success] = "Created!"
        redirect_to action: :edit, id: @featured_search
      else
        flash[:error] = @featured_search.errors.full_messages.to_sentence
        ensure_non_empty_filter_values
        render :new
      end
    end

    def update
      @featured_search = FeaturedSearch.find(params[:id])
      @featured_search.update(featured_search_params)
      if @featured_search.save
        flash[:success] = "Updated!"
        redirect_to action: :edit
      else
        flash[:error] = @featured_search.errors.full_messages.to_sentence
        ensure_non_empty_filter_values
        render :edit
      end
    end

    def index
      @feature_categories = FeatureCategory.all
    end

    def destroy
      @featured_search ||= FeaturedSearchForm.find(params[:id])
      if @featured_search.destroy
        flash[:success] = "Deleted feature at #{@featured_search.slug}!"
      else
        flash[:error] = @featured_search.errors.full_messages.to_sentence
      end
      redirect_to action: :index
    end

    private

    def featured_search_params
      res = params.require(:featured_search).permit(:feature_category_id, :label, :slug, :description, :priority, :url, :thumbnail_url, featured_search_values_attributes: [:id, :value, :_destroy])
      Rails.logger.debug 'PARAMS RECEIVED:'
      Rails.logger.debug res
      res
    end

    # When we render a blank form, there must exist an empty FeaturedSearchValue object to supply to the form helper
    def ensure_non_empty_filter_values
        @featured_search.featured_search_values.build if @featured_search.featured_search_values.empty?
    end
  end
end
