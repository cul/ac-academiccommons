module V1::Entities
  class DataFeedResponse < Grape::Entity
    expose :total_number_of_results do |solr_response, options|
      solr_response.dig('response', 'numFound')
    end

    expose :records, using: FullRecord do |solr_response, options|
      solr_response['response']['docs'].map { |d| SolrDocument.new(d).to_semantic_values }
    end
  end
end
