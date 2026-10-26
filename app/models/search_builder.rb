class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  # We are waiting until the vite migration is complete to add the range limit slider back --- ACHYDRA 1022
  # include BlacklightRangeLimit::RangeLimitBuilder

  # add to the beginning of the processing chain
  default_processor_chain.unshift(:validate_sort)
  # Must run after :add_query_to_solr. If solr_parameters[:q] is already set when add_query_to_solr appends the user's
  # query, Blacklight moves both into a JSON query DSL request, which gets sent to the 'advanced' solr path (a 404).
  # default_processor_chain.insert(default_processor_chain.index(:add_query_to_solr) + 1, :handle_vector_search_fields)
  self.default_processor_chain += [:handle_vector_search_fields]

  def validate_sort(_solr_parameters)
    return unless blacklight_params['sort']

    blacklight_params.delete('sort') unless
    blacklight_config[:sort_fields].dig(blacklight_params['sort'])
  end

  def handle_vector_search_fields(solr_parameters)
    # Check if search field corresponds to a registered embedding model
    search_field = blacklight_params[:search_field]
    query_text = blacklight_params[:q]
    model_for_search_field = Rails.application.config.embedding_service.dig(:supported_embeddings, search_field.to_sym)

    if query_text.present? && search_field.present? && model_for_search_field.present?
      model_name = search_field # Reassign to a better-named variable for use with the lines below

      default_min_vector_similarity = Rails.application.config.embedding_service.dig(
        :supported_embeddings, model_name.to_sym, :default_min_vector_similarity
      ) || 0.9 # Fall back to 0.9 if no default threshold has been supplied

      min_vector_similarity = if blacklight_params[:min_vector_similarity].to_f.positive?
                                blacklight_params[:min_vector_similarity].to_f
                              else
                                default_min_vector_similarity
                              end
      puts "min_vector_similarity: #{min_vector_similarity}"

      query_as_vector = EmbeddingService::Endpoint.embedding_for(model_name: model_name, text: query_text)
      if query_as_vector.present?
        vector_search_field_name = EmbeddingService::Endpoint.vector_search_field_name_for(model_name)
        solr_parameters[:q] =
          "{!vectorSimilarity f=#{vector_search_field_name} "\
          "minReturn=#{min_vector_similarity}}[#{query_as_vector.join(', ')}]"

        # Change blacklight config solr_path to the solr endpoint that supports vector searches
        blacklight_config.solr_path = 'select-vector'
        # The default qt will be in conflict with our change in solr_path, and we _could_ change :qt to match,
        # but since :qt is deprecated in Solr 9 we're better off just removing the :qt parameter here.
        solr_parameters.delete(:qt)
        return
      else
        Rails.logger.error('The vector embedding service is not reachable right now, so vector search will not work. Falling back to default search behavior.')
      end
    end

    # For non-vector searches, the blacklight config solr_path should be our normal 'select' path
    blacklight_config.solr_path = 'select'
  end
end
