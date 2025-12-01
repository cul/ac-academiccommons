module V1
  module Helpers
    module Solr
      extend Grape::API::Helpers

      SEARCH_TYPES = %i[keyword semantic subject title].freeze
      FILTERS = %i[author author_id date department subject type columbia_series degree_level].freeze
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

      def query_solr(params: {}, with_facets: true)
        AcademicCommons.search do |solr_params|
          FILTERS.map do |filter|
            params.fetch(filter, []).map { |value| solr_params.filter(MAP_TO_SOLR_FIELD[filter], value) }
          end

          solr_params.q params[:q]
          solr_params.sort_by SORT_TO_SOLR_SORT.dig(params[:sort], params[:order])
          solr_params.start((params[:page].to_i - 1) * params[:per_page].to_i)
          solr_params.rows params[:per_page].to_i
          solr_params.aggregators_with_assets

          if with_facets
            solr_params.facet_by(*FACETS.map { |f| MAP_TO_SOLR_FIELD[f] })
            solr_params.facet_limit(5)
          end

          solr_params.search_type(params[:search_type]) if params.key?(:search_type)
        end
      rescue StandardError => e
        Rails.logger.error e
        error! 'unexpected error', 500
      end
    end
  end
end
