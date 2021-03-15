# frozen_string_literal: true
module AcademicCommons
  module FeaturedSearches
    MINIMUM_DOC_COUNT = 2
    # Finds FeaturedSearch entities relevant to the Solr response
    #
    # @param SolrResponse solr response structure including facets and documents
    # @return [FeaturedSearch] the searches matching the response filters and threshold criteria
    def self.for(response)
      document_count = response&.total
      return [] if document_count.to_i < MINIMUM_DOC_COUNT
      conditions = {}
      feature_categories.each do |category|
        show_threshold = (category.threshold / 100) * document_count
        candidates = response.aggregations[category.field_name]&.items || []
        candidates = candidates.select { |item| item.hits >= show_threshold }.map(&:value)
        conditions[category.id] = candidates if candidates.present?
      end
      conditions.inject(self) { |relation, c|
        relation.or(FeaturedSearch.where(feature_category_id: c[0], filter_value: c[1]))
      }.order('priority DESC')
    end

    # reflect the relation back
    # this method is syntactic sugar for query building
    def self.or(relation)
      relation
    end

    # return an empty array
    # this method is syntactic sugar for query building
    def self.order(_sort_value)
      []
    end

    # cachable list of feature categories
    # @return Iterable<FeatureCategory> categories
    def self.feature_categories
      FeatureCategory.all
    end
  end
end
