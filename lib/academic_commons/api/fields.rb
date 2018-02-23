module AcademicCommons::API
  module Fields
    SEARCH_TYPES = %w(keyword title subject).freeze
    FILTERS = %w(author author_id date department subject type series).freeze
    SORT    = %w(best_match date title created_at).freeze
    FORMATS = %w(json rss).freeze
    ORDER   = %w(desc asc).freeze
    FACETS = %w(author date department subject type series).freeze
    
    MAP_TO_SOLR_FIELD = SolrDocument.field_semantics
  end
end
