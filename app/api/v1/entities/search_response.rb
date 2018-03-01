module V1::Entities
  class Parameters < Grape::Entity
    [:q, :sort, :order, :search_type].each do |key|
      expose key
    end

    expose :filters do
      V1::Helpers::Solr::FILTERS.each do |filter|
        expose filter, expose_nil: false
      end
    end
  end

  class SearchResponse < Grape::Entity
    expose :total_number_of_results do |solr_response, options|
      solr_response.dig('response', 'numFound')
    end

    expose :per_page do |solr_response, options|
      options[:params][:per_page]
    end

    expose :page do |solr_response, options|
      options[:params][:page]
    end

    expose :params, using: Parameters do |solr_response, options|
      options[:params]
    end

    expose :records, using: Record do |solr_response, options|
      solr_response['response']['docs'].map { |d| SolrDocument.new(d).to_semantic_values }
    end

    expose :facets do |solr_response, options|
      facet_fields = solr_response.dig('facet_counts', 'facet_fields')

      V1::Helpers::Solr::FACETS.each_with_object({}) do |facet, hash|
         fields = facet_fields[V1::Helpers::Solr::MAP_TO_SOLR_FIELD[facet]]
         hash[facet] = Hash[*fields] unless fields.blank?
      end
    end
  end
end
