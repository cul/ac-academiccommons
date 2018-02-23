class ApiController < ApplicationController
  # GET /api/v1/search(/:type_of_search)
  def search
    api_response = AcademicCommons::API.search(search_params)

    respond_to do |f|
      f.json { render json: api_response.body, status: api_response.status }
      f.rss  { render plain: api_response.body, status: api_response.status, content_type: 'application/rss+xml' }
    end
  end

  # GET /api/v1/feed(/:id)
  def feed
    # authorized = valid_api_key?
    # f = feed_params[:format] || :json
    # api_response = AcademicCommons::API.feed(feed_params[:key], feed_params[:format], authorized)

    # respond_to do |f|
    #   f.json { render json: api_response.body, status: api_response.status }
    # end
  end

  private

  def valid_api_key?
    true
  end

  def feed_params
    params.permit(:key, :format)
  end

  def search_params
    filters = AcademicCommons::API::Fields::FILTERS.map{ |f| [f, []] }.to_h
    params.permit(:search_type, :q, :page, :per_page, :format, :sort, :order, filters)
  end
end
