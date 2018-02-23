module AcademicCommons::API
  module Feed
    class Request < BaseRequest
      DEFAULT_PARAMS = {
        search_type: 'keyword',
        page: 1,
        per_page: 100_000,
        format: 'json',
        sort: 'best_match',
        order: 'desc'
      }.freeze

      def initialize(key, authorized)
        @errors = []

        @response = if !authorized
                      ErrorResponse.new(:json, ["Not Authorized"], :not_authorized)
                    elsif feed = Feed.find(key)
                      @parameters = feed.parameters.reverse_merge(DEFAULT_PARAMS)
                      if params_valid?
                        solr_response = query_solr(parameters: parameters, with_facets: false)
                        SuccessResponse.new(parameters, solr_response: solr_response)
                      else
                        ErrorResponse.new(parameters[:format], errors, :bad_request)
                      end
                    else
                      ErrorResponse.new(:json, ["Feed key invalid"], :bad_request)
                    end
      end


      def params_valid?
        valid_value(:search_type, SEARCH_TYPES)
        valid_value(:sort, SORT)
        valid_value(:format, FORMATS)
        valid_value(:order, ORDER)

        @errors.empty?
      end
    end
  end
end
