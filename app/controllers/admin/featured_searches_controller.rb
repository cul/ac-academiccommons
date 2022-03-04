# frozen_string_literal: true
module Admin
  class FeaturedSearchesController < AdminController
    load_and_authorize_resource

    def new
      @featured_search ||= FeaturedSearch.new
    end

    def edit
      @featured_search ||= FeaturedSearch.find(params[:id])
    end

    def create
      @featured_search = FeaturedSearch.new(featured_search_params)
      if @featured_search.save
        flash[:success] = "Created!"
        redirect_to action: :edit, id: @featured_search
      else
        flash[:error] = @featured_search.errors.full_messages.to_sentence
        render :new
      end
    end

    def update
      @featured_search = FeaturedSearch.find(params[:id])
      @featured_search.update_attributes(featured_search_params)
      if @featured_search.save
        flash[:success] = "Updated!"
        redirect_to action: :edit
      else
        flash[:error] = @featured_search.errors.full_messages.to_sentence
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
        params.require(:featured_search).permit(:feature_category_id, :label, :slug, :description, :priority, :url, :thumbnail_url, featured_search_values_attributes: [:id, :value, :_destroy])
      end
  end
end
