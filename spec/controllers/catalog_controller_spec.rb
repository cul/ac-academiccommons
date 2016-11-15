require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  let(:empty_response) { Blacklight::Solr::Response.new({}, {}) }

  describe "#index" do
    context "filters users by uni" do
      let(:uni_filter) { 'author_uni:abc123' }
      let(:expected_params) do
        {
          qt: 'search',
          fq: [uni_filter, "has_model_ssim:\"info:fedora/ldpd:ContentAggregator\""],
          page: nil,
          q: '',
          sort: 'record_creation_date desc',
          rows: '500',
          fl: 'title_display,id,author_facet,author_display,record_creation_date,handle,abstract,author_uni,subject_facet,department_facet,genre_facet'
        }
      end

      it 'merges :fq parameter' do
        expect(@controller.repository).to receive(:send_and_receive)
          .with('select', hash_including(expected_params))
          .and_return(empty_response)
        get :index, fq: 'author_uni:abc123', format: 'rss'
      end
    end
  end

  describe '#custom_results' do
    context 'when :fq in request' do
      let(:uni_filter) { 'author_uni:abc123' }
      let(:expected_params) do
        {
          qt: 'search',
          fq: [uni_filter, "has_model_ssim:\"info:fedora/ldpd:ContentAggregator\""],
          page: nil,
          q: '',
          sort: 'record_creation_date desc',
          rows: '500',
          fl: 'title_display,id,author_facet,author_display,record_creation_date,handle,abstract,author_uni,subject_facet,department_facet,genre_facet'
        }
      end

      before :each do
        allow(@controller).to receive(:params).and_return( { fq: uni_filter } )
      end

      it 'correctly merges :fq parameters' do
        expect(@controller.repository).to receive(:send_and_receive)
          .with('select', expected_params)
          .and_return(empty_response)
        @controller.instance_eval { custom_results }
      end
    end
  end
end
