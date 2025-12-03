# frozen_string_literal: true

module EmbeddingService
  class Endpoint
    MODEL_MAPPING = {
      'bge_base_en_15_768' => {
        namespace: 'BAAI',
        model: 'bge-base-en-v1.5',
        dimensions: 768,
        summarize: false
      },
      'bge_base_en_15_1024' => {
        namespace: 'BAAI',
        model: 'bge-large-en-v1.5',
        dimensions: 1024,
        summarize: false
      }
    }.freeze

    def self.generate_vector_embedding(destination_url, model_details, field_value) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      uri = URI("#{destination_url}/vectorize")
      params = create_params(model_details, field_value)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.to_s.start_with?('https:')

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.set_form_data(params)

      begin
        response = http.request(request)
        parsed_response = ::JSON.parse(response.body)
        if parsed_response['embeddings']
          Rails.logger.debug do
            "Embedding generated successfully for text (first 20 chars): #{field_value.truncate(20)}"
          end
          parsed_response['embeddings']
        else
          Rails.logger.warn { "Embedding service returned no embeddings for: #{field_value.truncate(20)}" }
          nil
        end
      rescue StandardError => e
        Rails.logger.error do
          "Error generating embedding for: #{field_value.truncate(20)} -- #{e.class}: #{e.message}"
        end
        raise EmbeddingService::GenerationError.new("Embedding failed for '#{field_value.truncate(20)}'"), cause: e
      end
    end

    def self.create_params(model_details, field_value)
      {
        model: "#{model_details[:namespace]}/#{model_details[:model]}",
        summarize: model_details[:summarize].to_s,
        text: truncate_value(field_value)
      }
    end

    def self.truncate_value(field_value)
      field_value[0, 512]
    end
  end
end
