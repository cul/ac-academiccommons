module V1
  class DataFeed < Grape::API
    content_type :json, 'application/json'
    default_format :json

    DEFAULT_KEYS = {
      'doctoral' => { 'type': ['Theses'], 'degree_level': ['Doctoral'] },
      'masters' => { 'type': ['Theses'], 'degree_level': ['Master\'s'] },
      'ncdp' => { 'department': ['National Center for Disaster Preparedness'] }
    }.freeze

    DEFAULT_PARAMS = {
      'sort': 'date', 'order': 'desc'
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
        desc 'Retrieves data feed. Key maps to a set of preconfigured search result filters',
             success: { code: 202, message: 'successful response' },
             failure: [
               { code: 400, message: 'invalid parameter' },
               { code: 401, message: 'not authorized' }
             ]
        params do
          requires :key, type: String
          optional :page, type: Integer, default: 1
          optional :per_page, type: Integer, default: 100, values: 1..10_000
        end
        get do
          safe_params = declared(params)
          key = safe_params[:key]
          feed = if DEFAULT_KEYS.key? key
                   DEFAULT_KEYS[key]
                 elsif ::DataFeed.where(key: key).exists?
                   ::DataFeed.find_by(key: key).search_fields
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
