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
      thresholds = category_thresholds(document_count)
      conditions = build_conditions(response.aggregations, thresholds)
      return [] unless conditions.present?
      build_relation(conditions).select do |feature|
        feature.featured_search_values.map { |val| conditions[feature.feature_category_id].fetch(val.value, 0) }.sum >= thresholds[feature.feature_category_id][:show]
      end
    end

    def self.build_conditions(aggregations, thresholds)
      conditions = {}
      feature_categories.each do |id, props|
        candidates = aggregations[props[:field_name]]&.items || []
        candidates = candidates.select { |item| item.hits >= thresholds[id][:query] }.map { |i| [i.value, i.hits] }.to_h
        conditions[id] = candidates if candidates.present?
      end
      conditions
    end

    def self.build_relation(conditions)
      conditions.inject(self) { |relation, c|
        relation.or(FeaturedSearch.where(feature_category_id: c[0], 'featured_search_values.value'.to_sym => c[1].keys))
      }.includes(:featured_search_values).order('priority DESC')
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

    # cached map of feature category ids to threshold and field_name properties
    # @return Hash<id, Hash> categories
    def self.feature_categories
      Rails.cache.fetch(FeatureCategory::THRESHOLD_CACHE_KEY) do
        FeatureCategory.all.map { |e| [e.id, { threshold: e.threshold, field_name: e.field_name }] }.to_h
      end
    end

    def self.category_thresholds(document_count)
      thresholds = {}
      feature_categories.each do |id, props|
        thresholds[id] = {}
        thresholds[id][:show] = (props[:threshold] / 100) * document_count
        thresholds[id][:query] = thresholds[id][:show] / 3
      end
      thresholds
    end

    def self.to_fq(feature)
      search_value = feature.featured_search_values.map(&:value).join('" OR "')
      "#{feature.feature_category.field_name}:(\"#{search_value}\")"
    end
  end
end
