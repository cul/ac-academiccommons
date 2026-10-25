# frozen_string_literal: true

module EmbeddingService
  class Exceptions
    class EmbeddingServiceError < StandardError; end
  end

  class Endpoint
    def self.truncate_value(text_value, max_length)
      return text_value.truncate(512, separator: '', omission: '') if text_value

      nil
    end

    def self.vector_search_field_name_for(model_name, stored: false)
      model_dimensions = Rails.application.config.embedding_service[:supported_embeddings][model_name.to_sym][:dimensions]
      "#{model_name}_vector#{model_dimensions}#{stored ? 's' : ''}i"
    end

    def self.generate_vector_embeddings(document_id:, text:)
      Rails.application.config.embedding_service[:supported_embeddings].each do |model_name, opts|
        truncated_text = self.truncate_value(text, opts[:input_limit])
        if truncated_text.length != text.length
          Rails.logger.info(
            "Truncated #{document_id} text to #{truncated_text.length} because it was "\
            "longer than the #{model_name} configuration allows."
          )
        end

        yield model_name, self.embedding_for(model_name: model_name, text: truncated_text)
      end
    end

    def self.embedding_for(model_name:, text:)
      conn = Faraday.new(url: Rails.application.config.embedding_service[:base_url])
      response = conn.post('/embeddings/generate') do |req|
        # Set the required headers
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{Rails.application.config.embedding_service[:api_key]}"

        # Convert your Ruby hash payload to a JSON string
        req.body = { model: model_name, input: text }.to_json
      end

      if response.success?
        # A successful response body is a float array representation of the embedding.
        arr = JSON.parse(response.body)

        # Solr 9.8.1 runs into issues with floats that have a lot of significant digits, and occasionally we'll get
        # floats like this in the array returned from our vector embedding service.  It appears that Solr has an issue
        # parsing a string with too many digits.  Here's a specific problematic example we encountered:
        # 0.0000024306916657224065
        #
        # And the error we got from Solr:
        #
        # Caused by: org.apache.solr.common.SolrException: Error while creating field
        # 'amazon_titan_embed_text_v2_1024d_vector1024i{type=knn1024_vector,properties=indexed,omitNorms,
        # omitTermFreqAndPositions,useDocValuesAsStored}'from value '[...]'.
        #
        # In the error above '[...]' is a placeholder for the actual float array in the error message.
        #
        # To work around this problem, we'll limit the number of significant digits for each float.  It hopefully won't
        # have any noticeable effect on our search results.  The alternative is being unable to index certain values
        # at all, so it seems like an okay tradeoff.
        # 17 decimal places is too high, and we've also had problems with 14 decomal places. Floats with 13 decimal
        # places have worked so far.  We might need to go lower than 13, but let's wait until we run into this issue
        # again.  Ideally we won't run into it because there should only ever be one digit before the decimal place in
        # our float array values (since they're between -1 and 1).  So we're doing the least amount of truncation that
        # we can.  Maybe this issue will be fixed in a later version of Solr.
        arr = arr.map { |x| Float(format('%.13g', x)) }
        return arr
      end

      error_response_json = JSON.parse(response.body)
      Rails.logger.error(
        "Embedding service error: #{error_response_json['message'] || 'An unexpected error occurred.'}"
      )
      # TODO: Would it be useful to raise an exception here instead?
      # raise EmbeddingService::Exceptions::EmbeddingServiceError,
      #       error_response_json['message'] || 'An unexpected error occurred.'
      nil
    end
  end
end
