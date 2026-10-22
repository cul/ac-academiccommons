module V1
  class DataFeed < Grape::API
    content_type :json, 'application/json'
    default_format :json

    params do
      requires :key, type: String
      optional :page, type: Integer, default: 1
      optional :per_page, type: Integer, default: 100, values: 1..10_000
    end

    DEFAULT_KEYS = {
      'doctoral' => { 'type': ['Theses'], 'degree_level': ['Doctoral'] },
      'masters' => { 'type': ['Theses'], 'degree_level': ['Master\'s'] },
      'ncdp' => { 'department': ['National Center for Disaster Preparedness'] }
    }.freeze

    DEFAULT_PARAMS = {
      'sort': 'date', 'order': 'desc', 'page': 1, 'per_page': 100
    }.freeze

    auth :http_token do |token, _options|
      valid_tokens = Token.where(scope: Token::DATAFEED).map(&:token)
      valid_tokens.include?(token)
    end

    namespace :data_feed do
      desc 'Lists all available data feed keys',
           success: { code: 202, message: 'successful response' },
           failure: { code: 401, message: 'not authorized' }
      get do
        keys = ::DataFeed.all.map(&:key) + DEFAULT_KEYS.keys
        present :keys, keys
      end

      route_param :key do
        desc 'Retrieves data feed. Key maps to a set of preconfigured search results',
             success: { code: 202, message: 'successful response' },
             failure: [
               { code: 400, message: 'invalid parameter' },
               { code: 401, message: 'not authorized' }
             ]
        get do
          safe_params = declared(params)
          # check authorization
          # error! 'Access Denied', 401 if credentials not valid
          feed = if DEFAULT_KEYS.key? safe_params[:key]
                   DEFAULT_KEYS[safe_params[:key]]
                 elsif ::DataFeed.where(key: safe_params[:key]).exists?
                   ::DataFeed.find_by(key: safe_params[:key]).search_fields
                 else
                   error! 'Feed key invalid', 400
                 end
          solr_params = feed.merge(DEFAULT_PARAMS, page: safe_params[:page], per_page: safe_params[:per_page])
          solr_response = query_solr(params: solr_params, with_facets: false)
          present solr_response, with: Entities::DataFeedResponse, params: safe_params
        end
      end
    end
  end
end
