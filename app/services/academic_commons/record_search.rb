# frozen_string_literal: true

module AcademicCommons
  class RecordSearch
    SEARCH_TYPES = V1::Helpers::Solr::SEARCH_TYPES
    SORT    = V1::Helpers::Solr::SORT
    ORDER   = V1::Helpers::Solr::ORDER
    FACETS  = V1::Helpers::Solr::FACETS

    SORT_TO_SOLR_SORT = V1::Helpers::Solr::SORT_TO_SOLR_SORT

    MAP_TO_SOLR_FIELD = SolrDocument.field_semantics

    def self.query_solr(order:, page:, per_page:, q:, sort:, search_type: :semantic)
      AcademicCommons.search do |solr_params|
        solr_params.q q
        solr_params.sort_by SORT_TO_SOLR_SORT.dig(sort, order)
        solr_params.start((page.to_i - 1) * per_page.to_i)
        solr_params.rows per_page.to_i
        solr_params.aggregators_with_assets

        solr_params.search_type(search_type)
      end
    rescue StandardError => e
      Rails.logger.error e
      raise
    end

    def self.get_document(doi)
      response = AcademicCommons.search do |params|
        params.aggregators_with_assets
        params.id(doi)
        params.rows(1)
      end
      response.docs.first
    rescue StandardError => e
      Rails.logger.error e
      raise
    end

    def self.call(search_type:, q:, page:, per_page:, sort:, order:)
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
end
