module SolrHelpers
  extend Grape::API::Helpers
    SEARCH_TYPES = %w(keyword title subject).freeze
    FILTERS = %w(author author_id date department subject type series).freeze
    SORT    = %w(best_match date title created_at).freeze
    ORDER   = %w(desc asc).freeze
    FACETS = %w(author date department subject type series).freeze
    REQUIRED_FILTERS = ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""]

    SEARCH_TYPES_TO_QUERY = {
      'title' => { 'spellcheck.dictionary': 'title', qf: '${title_qf}', pf: '${title_pf}'},
      'subject' => { 'spellcheck.dictionary': 'subject', qf: '${subject_qf}', pf: '${subject_pf}'}
    }.freeze

    SORT_TO_SOLR_SORT = {
      'best_match' => {
        'asc' => 'score desc, pub_date_sort desc, title_sort asc',
        'desc' => 'score desc, pub_date_sort desc, title_sort asc'
      },
      'date' => {
        'asc' => 'pub_date_sort asc, title_sort asc',
        'desc' => 'pub_date_sort desc, title_sort asc'
      },
      'title' => {
        'asc'  => 'title_sort asc, pub_date_sort desc',
        'desc' => 'title_sort desc, pub_date_sort desc'
      }
    }.freeze

    MAP_TO_SOLR_FIELD = SolrDocument.field_semantics


  def query_solr(params: {}, with_facets: true)
    connection = AcademicCommons::Utils.rsolr
    solr_response = connection.get('select', params: solr_parameters(params, with_facets))
  end

  def solr_parameters(parameters, with_facets)
    filters = FILTERS.map do |filter|
      parameters.fetch(filter, []).map { |value| "#{MAP_TO_SOLR_FIELD[filter.to_sym]}:\"#{value}\"" }
    end.flatten

    solr_params = {
      q: parameters[:q],
      sort: SORT_TO_SOLR_SORT[parameters[:sort]][parameters[:order]],
      start: (parameters[:page].to_i - 1) * parameters[:per_page].to_i,
      rows: parameters[:per_page].to_i,
      fq: ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""].concat(filters),
      fl: '*', # default blacklight solr param
      qt: 'search' # default blacklight solr param
    }

    if with_facets
      solr_params[:facet] = 'true'
      solr_params['facet.field'] = []
      FACETS.each do |f|
        solr_key = MAP_TO_SOLR_FIELD[f.to_sym]
        solr_params['facet.field'].append(solr_key)
        solr_params["f.#{solr_key}.limit"] = 5
      end
    end

    if SEARCH_TYPES_TO_QUERY.key? parameters[:search_type]
      solr_params.merge!(SEARCH_TYPES_TO_QUERY[parameters[:search_type]])
    end
    puts solr_params

    solr_params
  end


end
