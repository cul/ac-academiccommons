class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  # add to the beginning of the processing chain
  default_processor_chain.unshift(:validate_sort)

  def validate_sort(_solr_parameters)
    return unless blacklight_params['sort']

    blacklight_params.delete('sort') unless
      blacklight_config[:sort_fields].dig(blacklight_params['sort'])
  end
end
