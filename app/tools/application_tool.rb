# frozen_string_literal: true

class ApplicationTool < ActionTool::Base
  SEARCH_TYPES = %i[keyword title subject].freeze
  SORT    = %i[best_match date title].freeze
  ORDER   = %i[desc asc].freeze
  FACETS  = %i[author date department subject type columbia_series].freeze

  SORT_TO_SOLR_SORT = {
    best_match: {
      asc: 'score desc, pub_date_isi desc, title_sort asc',
      desc: 'score desc, pub_date_isi desc, title_sort asc'
    },
    date: {
      asc: 'pub_date_isi asc, title_sort asc',
      desc: 'pub_date_isi desc, title_sort asc'
    },
    title: {
      asc: 'title_sort asc, pub_date_isi desc',
      desc: 'title_sort desc, pub_date_isi desc'
    }
  }.freeze

  MAP_TO_SOLR_FIELD = SolrDocument.field_semantics

  def query_solr(order:, page:, per_page:, q:, search_type:, sort:)
    AcademicCommons.search do |solr_params|
      solr_params.q q
      solr_params.sort_by SORT_TO_SOLR_SORT.dig(sort, order)
      solr_params.start((page.to_i - 1) * per_page.to_i)
      solr_params.rows per_page.to_i
      solr_params.aggregators_with_assets

      solr_params.search_type(search_type) if search_type
    end
  rescue StandardError => e
    Rails.logger.error e
    raise
  end

  def get_document(doi)
    response = AcademicCommons.search do |params|
      params.aggregators_with_assets
      params.id(doi)
      params.rows(1)
    end
    response.docs.first
  rescue StandardError
    Rails.logger.error e
    raise
  end
end
