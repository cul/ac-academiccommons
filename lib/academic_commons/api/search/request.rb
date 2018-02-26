module AcademicCommons::API
  module Search
    class Request < BaseRequest
      MAX_PER_PAGE = 100

      DEFAULT_PARAMS = {
        search_type: 'keyword',
        page: 1,
        per_page: 25,
        format: 'json',
        sort: 'best_match',
        order: 'desc'
      }.freeze

      attr_reader :parameters, :errors, :response

      # Returns response object
      def initialize(params)
        @errors = []
        @parameters = params
        with_facets = !params[:format].eql?('rss')

        @response = if params_valid?
                      @parameters = parameters.reverse_merge(DEFAULT_PARAMS)
                      solr_response = query_solr(params: @parameters, with_facets: with_facets)
                      SuccessfulResponse.new(parameters, solr_response: solr_response)
                    else
                      ErrorResponse.new(parameters[:format], errors, :bad_request)
                    end
      end

      private



      def params_valid?
        valid_value(:search_type, SEARCH_TYPES)
        valid_value(:sort, SORT)
        valid_value(:format, FORMATS)
        valid_value(:order, ORDER)

        valid_number(:per_page)
        valid_number(:page)

        value_not_greater_than(:per_page, MAX_PER_PAGE)

        @errors.empty?
      end
    end
  end
end
