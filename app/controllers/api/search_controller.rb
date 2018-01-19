class Api::SearchController < ActionController::Base
  VALID_FILTERS = %w(author author_id date department subject type series)
  VALID_SORT    = %w(best_match date title created_at)
  VALID_FORMATS = %w(json rss)
  VALID_ORDER   = %w(desc asc)
  REQUIRED_FILTERS = ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""]
  KEY_TO_SOLR_FIELD = SolrDocument.field_semantics

  SORT_TO_SOLR_SORT = {
    'best_match'      => { 'desc' => '', 'asc'=> '' },
    'date'            => { 'desc' => '', 'asc'=> '' },
    'title'           => { 'desc' => '', 'asc'=> '' },
    'record_creation' => { 'desc' => '', 'asc'=> '' }
  }

  DEFAULT_PARAMS = {
    search_type: 'keyword',
    page: 1,
    per_page: 25,
    format: 'json',
    sort: 'best_match',
    order: 'desc'
  }

  # GET /api/v1/search(/:type_of_search)
  def search
    if search_params_invalid?
      respond_to do |f|       # error_json: { status: "", message: "", code: ""}
        f.json { render json: { error: "Invalid parameters." }, status: :bad_request }
      end
    else
      query_params = search_params.reverse_merge(DEFAULT_PARAMS)
      connection = AcademicCommons::Utils.rsolr
      response = connection.get('select', params: convert_to_solr_params(query_params))

      respond_to do |f|
        f.json { render json: json_body(query_params, response) }
        f.rss { render rss: '' }
      end
    end
  end

  def json_body(query_params, response)
    json = {
      total_number_of_results: response['response']['numFound'],
      page: query_params[:page],
      per_page: query_params[:per_page],
      params: {},
      records: []
    }

    [:q, :sort, :order, :search_type].each do |key|
      json[:params][key] = query_params[key]
    end

    # add filters
    json[:params][:filters] = query_params.select{ |k, _| VALID_FILTERS.include?(k) }

    # add records
    json[:records] = response['response']['docs'].map { |d| SolrDocument.new(d).to_ac_json_api }

    json
  end

  def search_params_invalid?
    # Check that sort, formats, and order are valid params.
    checks = [
      search_params[:sort].blank? || VALID_SORT.include?(search_params[:sort]),
      search_params[:format].blank? || VALID_FORMATS.include?(search_params[:format]),
      search_params[:order].blank? || VALID_ORDER.include?(search_params[:order]),
      [:per_page, :page].all? { |v| search_params[v].blank? || /^\d+$/ === search_params[v] },
      search_params[:per_page].blank? || search_params[:per_page].to_i < 100
    ]


    # TODO: check for 0

    # per_page and page needs to be an integer
    !checks.all?
  end

  def convert_to_solr_params(parameters)
     filters = VALID_FILTERS.map do |filter|
       parameters.fetch(filter, []).map { |value| "#{KEY_TO_SOLR_FIELD[filter.to_sym]}:\"#{value}\"" }
     end.flatten

    solr_params = {
      q: parameters[:q],
      sort: 'score desc, pub_date_sort desc, title_sort asc',
      start: (parameters[:page].to_i - 1) * parameters[:per_page].to_i,
      rows: parameters[:per_page].to_i,
      fq: ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""].concat(filters),
      fl: '*', # default blacklight solr param
      qt: 'search' # default blacklight solr param
    }
    puts solr_params
    solr_params
  end

  def search_params
    filters = VALID_FILTERS.map{ |f| [f, []] }.to_h
    params.permit(:type_of_search, :q, :page, :per_page, :format, :sort, :order, filters)
  end
end
