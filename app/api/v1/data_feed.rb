module V1
  class DataFeed < Grape::API
    content_type :json, 'application/json'
    default_format :json

    params do
      requires :key
    end

    DEFAULT_PARAMS = {
      'sort' => 'best_match', 'order': 'desc', 'page': 1, 'per_page': 100_000
    }

    desc 'Retrived data feed for key. Key maps to a set of preconfigured search results'
    get '/data_feed/:key' do
      # check authorization
      # error! 'Access Denied', 401 if credentials not valid
      feed = if params[:key] == 'doctoral'
               { 'type': ['Theses'], 'degree_level': ['Doctoral'] }
             elsif params[:key] == 'master\'s'
               { 'type': ['Theses'], 'degree_level': ['Master\'s'] }
             else
               error! 'Feed key invalid', 403
             end
      solr_response = query_solr(params: feed.merge(DEFAULT_PARAMS), with_facets: false)
      present solr_response, with: Entities::DataFeedResponse, params: params

    end
  end
end
