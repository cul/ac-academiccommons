# frozen_string_literal: true

module AcademicCommons
  class SearchParameters
    MAX_ROWS = 100_000

    SEARCH_FIELD_KEYWORD = :keyword
    SEARCH_FIELD_SEMANTIC = :semantic
    SEARCH_FIELD_SUBJECT = :subject
    SEARCH_FIELD_TITLE = :title
    SEARCH_FIELDS = {
      SEARCH_FIELD_KEYWORD => {},
      SEARCH_FIELD_SEMANTIC => {},
      SEARCH_FIELD_SUBJECT => { 'spellcheck.dictionary': 'subject', qf: '${subject_qf}', pf: '${subject_pf}' },
      SEARCH_FIELD_TITLE => { 'spellcheck.dictionary': 'title', qf: '${title_qf}', pf: '${title_pf}' }
    }.freeze
    DEFAULT_SEARCH_FIELD = SEARCH_FIELD_KEYWORD

    SEARCH_PATH_SEMANTIC = 'select-vector'

    attr_reader :parameters

    def initialize(fq: [], qt: 'search', rows: MAX_ROWS, search_field: DEFAULT_SEARCH_FIELD)
      @parameters = {
        qt: qt || 'search',
        fq: Array(fq).compact,
        rows: rows || MAX_ROWS
      }
      @search_field = search_field
      search_field(@search_field)
    end

    def q(q)
      @parameters[:q] = q
      self
    end

    def filter(key, value)
      @parameters[:fq] << (value.match?(/^[\[\(].*[\]\)]$/) ? "#{key}:#{value}" : "#{key}:\"#{value}\"")
      self
    end

    def sort_by(sort)
      @parameters[:sort] = sort
      self
    end

    def rows(rows)
      @parameters[:rows] = rows
      self
    end

    def start(start)
      @parameters[:start] = start
      self
    end

    # Only returns fields specified, the default behavior is to return all the
    # fields. Modifies the :fl solr parameter. Use carefully! This limits the
    # fields returned and could lead to unintended results.
    def field_list(*fields)
      @parameters[:fl] = Array.wrap(fields).join(',')
      self
    end

    def request_handler(handler)
      @parameters[:qt] = handler
      self
    end

    def id(id)
      filter('id', id)
    end

    def assets_only
      filter('has_model_ssim', "(\"#{::GenericResource.to_class_uri}\" OR \"#{::Resource.to_class_uri}\")")
      self
    end

    def aggregators_only
      filter('has_model_ssim', ContentAggregator.to_class_uri)
      self
    end

    # USE CAREFULLY!!
    #
    # This method does not filter out embargoed assets. Assets are embargoed at the item level and
    # therefore the embargo status of an item should be checked before using this method.
    def assets_for(fedora3_pid)
      raise ArgumentError, 'Fedora 3 pid required' if fedora3_pid.blank?

      filter('cul_member_of_ssim', "info:fedora/#{fedora3_pid}")
      filter('object_state_ssi', 'A')
      rows(MAX_ROWS)
      without_facets
      self
    end

    # USE CAREFULLY!!
    #
    # Returns aggregators with a search results for its assets in a field named 'assets'.
    #
    # This method does not filter out embargoed assets. Assets are embargoed at the item level and
    # therefore the embargo status of an item should be checked before using this data.
    def aggregators_with_assets
      aggregators_only

      # Adding subquery for assets
      field_list('*', 'assets:[subquery]')
      @parameters[:'assets.fq'] = ['object_state_ssi:A', '{!terms f=cul_member_of_ssim v=$row.fedora3_uri_ssi}']

      @parameters[:'assets.rows'] = MAX_ROWS
      self
    end

    def embargoed_only
      filter('object_state_ssi', 'A')
      filter('free_to_read_start_date_dtsi', '[NOW+1DAYS TO *]')
    end

    def without_facets
      @parameters[:facet] = false
      self
    end

    def facet_by(*fields)
      @parameters[:facet] = true
      @parameters[:'facet.field'] = fields
      self
    end

    def add_facet_query(query_def)
      return unless query_def.present?
      @parameters[:'facet.query'] ||= []
      @parameters[:'facet.query'] += Array(query_def)
    end

    def facet_limit(limit)
      @parameters[:'facet.limit'] = limit
      self
    end

    def search_field(field)
      unless SEARCH_FIELDS.key?(field) || Rails.application.config.embedding_service[:supported_embeddings].key?(field.to_sym)
        raise ArgumentError, "search field #{field} not valid"
      end
      @search_field = field
      @parameters.merge!(SEARCH_FIELDS[field]) unless SEARCH_FIELDS[field].nil?
      self
    end

    def solr_path
      SEARCH_PATH_SEMANTIC if @search_field == SEARCH_FIELD_SEMANTIC
    end

    def vectorized_query(model_name, query_text)
      query_vector = EmbeddingService::Endpoint.embedding_for(model_name: model_name, text: query_text)

      if query_vector.nil?
        error_message = 'The vector embedding service is unreachable right now, so vector search will not work.'
        Rails.logger.error(error_message)
        raise error_message
      end

      query_vector
    end

    def vector_query_params
      raise 'requesting vector query params in no-vector search context' unless @search_field == SEARCH_FIELD_SEMANTIC

      model_name = get model name from query string params
      vector_search_field_name = EmbeddingService::Endpoint.vector_search_field_name_for(model_name: model_name)

      if parameters[:q]
        q = "{!knn f=searchable_text_vector768i topK=50}[#{vectorized_query(model_name, @parameters[:q]).join(', ')}]"
      end
      { q: q, qt: nil }
    end

    def to_h
      return parameters.merge(vector_query_params) if @search_field == SEARCH_FIELD_SEMANTIC

      parameters
    end
  end
end
