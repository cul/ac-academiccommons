module V1
  class DataFeed < Grape::API
    content_type :json, 'application/json'
    default_format :json

    params do
      requires :key
    end

    DEFAULT_PARAMS = {
      'sort' => 'best_match', 'order': 'desc', 'page': 1, 'per_page': 100_000
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
      # check authorization
      # error! 'Access Denied', 401 if credentials not valid
      feed = if params[:key] == 'doctoral'
               { 'type': ['Theses'], 'degree_level': ['Doctoral'] }
             elsif params[:key] == 'masters'
               { 'type': ['Theses'], 'degree_level': ['Master\'s'] }
             else
               error! 'Feed key invalid', 400
             end
      solr_response = query_solr(params: feed.merge(DEFAULT_PARAMS), with_facets: false)
      present solr_response, with: Entities::DataFeedResponse, params: params
    end
  end
end
