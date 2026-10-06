module V1
  class DataFeed < Grape::API
    content_type :json, 'application/json'
    default_format :json

    params do
      requires :key, type: String
      optional :page, type: Integer, default: 1
      optional :per_page, type: Integer, default: 100, values: 1..10_000
    end

    DEFAULT_PARAMS = {
      'sort' => 'date', 'order': 'desc', 'page': 1, 'per_page': 100
    }.freeze

    auth :http_token do |token, _options|
      valid_tokens = Token.where(scope: Token::DATAFEED).map(&:token)
      valid_tokens.include?(token)
    end

    desc 'Retrieves data feed. Key maps to a set of preconfigured search results',
         success: { code: 202, message: 'successful response' },
         failure: [
           { code: 400, message: 'invalid parameter' },
           { code: 401, message: 'not authorized' }
         ]
    get '/data_feed/:key' do
      safe_params = declared(params)
      # check authorization
      # error! 'Access Denied', 401 if credentials not valid
      feed = if safe_params[:key] == 'doctoral'
               { 'type': ['Theses'], 'degree_level': ['Doctoral'] }
             elsif safe_params[:key] == 'masters'
               { 'type': ['Theses'], 'degree_level': ['Master\'s'] }
             elsif safe_params[:key] == 'ncdp'
               { 'department': ['National Center for Disaster Preparedness'] }
             else
               error! 'Feed key invalid', 400
             end
      solr_params = feed.merge(DEFAULT_PARAMS, page: safe_params[:page], per_page: safe_params[:per_page])
      solr_response = query_solr(params: solr_params, with_facets: false)
      present solr_response, with: Entities::DataFeedResponse, params: safe_params
    end
  end
end
