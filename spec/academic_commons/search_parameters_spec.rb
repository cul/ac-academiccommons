# frozen_string_literal: true

require 'rails_helper'

describe AcademicCommons::SearchParameters do
  subject(:params) { described_class.new(embedding_endpoint: embedding_endpoint) }

  let(:embedding_endpoint) { nil }

  describe '#to_h' do
    it 'sets qt to "search"' do
      expect(params.to_h[:qt]).to eql('search')
    end
  end

  context 'when search_type is semantic' do
    let(:embedding_endpoint) { instance_double(EmbeddingService::Endpoint, generate_vector_embedding: [1, 2, 3, 4]) }

    before do
      params.search_type(described_class::SEARCH_TYPE_SEMANTIC)
    end

    describe '#solr_path' do
      it 'is the expected path value' do
        expect(params.solr_path).to eql(described_class::SEARCH_PATH_SEMANTIC)
      end
    end

    describe '#to_h' do
      it 'sets qt to nil' do
        expect(params.to_h[:qt]).to be_nil
      end

      it 'sets vector params' do
        params.q('a value')
        expect(params.to_h[:q]).to eql '{!knn f=searchable_text_vector768i topK=50}[1, 2, 3, 4]'
      end
    end
  end

  context 'when search_type is keyword' do
    before do
      params.search_type(described_class::SEARCH_TYPE_KEYWORD)
    end

    describe '#solr_path' do
      it 'is nil' do
        expect(params.solr_path).to be_nil
      end
    end
  end

  context 'when search_type is subject' do
    before do
      params.search_type(described_class::SEARCH_TYPE_SUBJECT)
    end

    describe '#solr_path' do
      it 'is nil' do
        expect(params.solr_path).to be_nil
      end
    end
  end

  context 'when search_type is title' do
    before do
      params.search_type(described_class::SEARCH_TYPE_TITLE)
    end

    describe '#solr_path' do
      it 'is nil' do
        expect(params.solr_path).to be_nil
      end
    end
  end
end
