# frozen_string_literal: true

require 'rails_helper'

describe EmbeddingService::Endpoint do
  subject(:endpoint) { described_class.new(model: 'bge_base_en_15_768') }

  describe '#endpoint_uri' do
    it 'appends /vectorize' do
      expect(endpoint.endpoint_uri).to eql URI('http://localhost:9292/vectorize')
    end
  end

  describe '#create_params' do
    let(:constant_model_params) do
      {
        model: 'BAAI/bge-base-en-v1.5',
        summarize: 'false'
      }
    end

    let(:input_text) { (1..39).inject('abcdef0123456789'.dup) { |m, _v| m << 'abcdef0123456789' } }

    it 'sets constant model params' do
      expect(endpoint.create_params('any_value')).to include(constant_model_params)
    end

    it 'truncates input text to 512 characters' do
      expect(endpoint.create_params(input_text)[:text].length).to be 512
    end
  end

  describe '#generate_vector_embedding' do
    let(:http_client) { instance_double(Net::HTTP) }
    let(:expected_embeddings) { [1, 2, 3, 4] }
    let(:embeddings_response) { JSON.generate({ embeddings: expected_embeddings }) }
    let(:successful_response) { instance_double(Net::HTTPResponse, body: embeddings_response) }

    before do
      allow(endpoint).to receive(:http_client).and_return(http_client)
      allow(http_client).to receive(:request)
        .with(instance_of(Net::HTTP::Post))
        .and_return(successful_response)
    end

    it 'parses a successful response in the expected format' do
      expect(endpoint.generate_vector_embedding('field_value')).to eql(expected_embeddings)
    end
  end
end
