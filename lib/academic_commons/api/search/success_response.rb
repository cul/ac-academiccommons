module AcademicCommons::API
  class Search
    class SuccessResponse < Response
      def initialize(parameters, solr_response: nil)
        @parameters = parameters
        @solr_response = solr_response

        # serialize to json
        body = send("#{parameters[:format]}_body")
        headers = [] # need to generate link headers

        super(:success, headers, body)
      end

      def json_body
        json = {
          total_number_of_results: @solr_response['response']['numFound'],
          page: @parameters[:page],
          per_page: @parameters[:per_page],
          params: {},
          records: []
        }

        [:q, :sort, :order, :search_type].each do |key|
          json[:params][key] = @parameters[key]
        end

        # add filters
        json[:params][:filters] = @parameters.select{ |k, _| Search::VALID_FILTERS.include?(k) }

        # add records
        json[:records] = @solr_response['response']['docs'].map { |d| SolrDocument.new(d).to_ac_json_api }

        json
      end

      def rss_body
      end
    end
  end
end
