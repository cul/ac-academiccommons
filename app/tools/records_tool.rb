# frozen_string_literal: true

class RecordsTool < ApplicationTool
  description 'Find Works in Academic Commons'

  # Optional: Add annotations to provide hints about the tool's behavior
  annotations(
    title: 'Academic Commons Works Search',
    read_only_hint: true,      # This tool only reads data
    open_world_hint: false     # This tool only accesses the local database
  )

  arguments do
    optional(:search_type)
      .filled(Dry::Types['string'].default('semantic')).value(included_in?: V1::Helpers::Solr::SEARCH_TYPES.map(&:to_s))
      .description(
        'type of search to use; use \'semantic\' for natural language queries, or \'keyword\' for term matching'
      )
    optional(:q)
      .maybe(:string).description('query string')
    optional(:page)
      .filled(Dry::Types['integer'].default(1)).value(gt?: 0).description('page number')
    optional(:per_page)
      .filled(Dry::Types['integer'].default(25)).value(included_in?: 1..100)
      .description('number of results returned per page; the maximum number of results is 100')
    optional(:sort)
      .filled(Dry::Types['string'].default('best_match')).value(included_in?: V1::Helpers::Solr::SORT.map(&:to_s))
      .description('sorting of search results')
    optional(:order)
      .filled(Dry::Types['string'].default('desc')).value(included_in?: V1::Helpers::Solr::ORDER.map(&:to_s))
      .description('ordering of results')
  end

  def call(order: :desc, page: 1, per_page: 25, q: nil, search_type: :keyword, sort: :best_match)
    solr_response = query_solr(
      order: order.to_sym, page: page, per_page: per_page,
      q: q, search_type: search_type.to_sym, sort: sort.to_sym
    )
    params = { page: page, per_page: per_page } # backwards compat with Grape API
    result_obj = V1::Entities::SearchResponse.represent(solr_response, params: params).as_json
    # not serializing params or facets for MCP responses for demo
    result_obj.delete(:params)
    result_obj.delete(:facets)
    JSON.generate(result_obj)
  end
end
