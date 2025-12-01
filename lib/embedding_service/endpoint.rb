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

    def self.truncate_value(field_value)
      field_value[0, 512] if field_value
    end

    def self.generate_vector_embedding(model:, text:, destination_url: nil)
      Endpoint.new(model: model, destination_url: destination_url).generate_vector_embedding(text)
    end

    def initialize(model:, destination_url: nil)
      @destination_url = destination_url || Rails.application.config.embedding_service[:base_url]
      @model_details = MODEL_MAPPING[model]
    end

    def endpoint_uri
      @endpoint_uri ||= URI("#{@destination_url}/vectorize")
    end

    def generate_vector_embedding(field_value)
      uri = endpoint_uri
      http = http_client(uri)

      begin
        response = http.request(create_request(uri, field_value))
        parse_response(response, field_value)
      rescue StandardError => e
        msg = "Error generating embedding for: #{field_value.truncate(20)} -- #{e.class}: #{e.message}"
        Rails.logger.error msg
        raise EmbeddingService::GenerationError.new(msg), cause: e
      end
    end

    def create_params(field_value)
      {
        model: "#{@model_details[:namespace]}/#{@model_details[:model]}",
        summarize: @model_details[:summarize].to_s,
        text: Endpoint.truncate_value(field_value)
      }
    end

    private

    def http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.to_s.start_with?('https:')
      http
    end

    def create_request(uri, field_value)
      params = create_params(field_value)
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.set_form_data(params)
      request
    end

    def parse_response(response, field_value)
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
    end
  end
end
