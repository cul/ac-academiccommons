module V1
  class Search < Grape::API
    content_type :json, 'application/json'
    default_format :json

    before do
      header['X-Robots-Tag'] = 'none'
    end

    params do
      optional :search_type, coerce: Symbol, default: :keyword,     values: V1::Helpers::Solr::SEARCH_TYPES,
                             desc: 'type of search to be conducted, in most cases a keyword search should be sufficient'
      optional :q,           type: String, desc: 'query string'
      optional :page,        type: Integer,  default: 1,            values: ->(v) { v.is_a?(Integer) && v.positive? }, desc: 'page number'
      optional :per_page,    type: Integer,  default: 25,           values: 1..100, desc: 'number of results returned per page; the maximum number of results is 100'
      optional :sort,        coerce: Symbol, default: :best_match,  values: V1::Helpers::Solr::SORT, desc: 'sorting of search results'
      optional :order,       coerce: Symbol, default: :desc,        values: V1::Helpers::Solr::ORDER, desc: 'ordering of results'

      Helpers::Solr::FILTERS.each do |filter|
        optional filter, type: Array[String], documentation: { desc: "#{filter} filter", param_type: 'query', collectionFormat: 'multi' }
      end
    end

    desc 'Query to conduct searches through all Academic Commons records',
         success: { code: 202, message: 'successful response' },
         failure: [
           { code: 400, message: 'invalid parameters' },
           { code: 500, message: 'unexpected error' }
         ],
         produces: ['application/json']
    get :search do
      solr_response = query_solr(params: params)
      present solr_response, with: Entities::SearchResponse, params: params
    end
  end
end
