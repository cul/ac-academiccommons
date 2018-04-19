module V1
  module Entities
    class DataFeedResponse < Grape::Entity
      expose :total_number_of_results do |solr_response, _options|
        solr_response.dig('response', 'numFound')
      end

      expose :records, using: FullRecord do |solr_response, _options|
        solr_response['response']['docs'].map { |d| SolrDocument.new(d).to_semantic_values }
      end
    end
  end
end
