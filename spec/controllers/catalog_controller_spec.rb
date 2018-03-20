require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  let(:empty_response) { Blacklight::Solr::Response.new({}, {}) }

  describe '#index' do
    context 'format: rss' do
      context 'search query' do
        let(:query) { 'alice' }
        let(:expected_params) do
          {
            page: nil,
            qt: 'search',
            q: query,
            fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
            sort: 'record_creation_dtsi desc',
            rows: '500',
            fl: 'title_ssi,id,author_ssim,author_display,record_creation_dtsi,cul_doi_ssi,abstract_ssi,author_uni_ssim,subject_ssim,department_ssim,genre_ssim'
          }
        end

        xit 'correctly creates solr query' do
          expect(@controller.repository).to receive(:send_and_receive)
            .with('select', hash_including(expected_params))
            .and_return(empty_response)
          get :index, q: query, format: 'rss'
        end

        xit 'returns rss feed with appropriate information'
      end

      context 'search query with row limit' do
        let(:query) { 'alice' }
        let(:expected_params) do
          {
            page: nil,
            qt: 'search',
            q: query,
            fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
            sort: 'record_creation_dtsi desc',
            rows: '10',
            fl: 'title_ssi,id,author_ssim,author_display,record_creation_dtsi,cul_doi_ssi,abstract_ssi,author_uni_ssim,subject_ssim,department_ssim,genre_ssim'
          }
        end

        xit 'correctly creates solr query' do
          expect(@controller.repository).to receive(:send_and_receive)
            .with('select', hash_including(expected_params))
            .and_return(empty_response)
          get :index, q: query, rows: '10', format: 'rss'
        end
      end

      context 'when filtering by organization using :f' do
        # /catalog.rss?f%5Borganization_ssim%5D%5B%5D=Teachers+College&sort=record_creation_dtsi+desc
        let(:expected_params) do
          {
            'qt' => 'search',
            'facet.field' =>
              ['author_ssim', 'department_ssim', 'subject_ssim', 'genre_ssim', 'pub_date_isi', 'series_ssim', 'language_ssim', 'type_of_resource_ssim'],
            'facet.query' => ['degree_level_ssim:0', 'degree_level_ssim:1', 'degree_level_ssim:2'],
            'facet.pivot' => [],
            'fq' => ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"', '{!raw f=organization_ssim}Teachers College'],
            'hl.fl' => [],
            'rows' => 100,
            'q' => '',
            'facet' => true,
            'f.author_ssim.facet.limit' => 3,
            'f.department_ssim.facet.limit' => 3,
            'f.subject_ssim.facet.limit' => 3,
            'f.genre_ssim.facet.limit' => 3,
            'f.pub_date_isi.facet.limit' => 3,
            'f.series_ssim.facet.limit' => 3,
            'sort' => 'record_create_date desc',
            'fl' => 'title_ssi,id,author_ssim,author_display,record_creation_dtsi,cul_doi_ssi,abstract_ssi,author_uni_ssim,subject_ssim,department_ssim,genre_ssim'
          }
        end

        xit 'correctly creates solr query' do
          expect(@controller.repository).to receive(:send_and_receive)
            .with('select', expected_params)
            .and_return(empty_response)
          get :index, f: { 'organization_ssim' => ['Teachers College'] },
                      sort: 'record_create_date desc', format: 'rss'
        end
      end

      context 'facets by department'

      context 'filters users by uni' do
        let(:uni_filter) { 'author_uni_ssim:abc123' }
        let(:expected_params) do
          {
            qt: 'search',
            fq: [uni_filter, 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
            page: nil,
            q: '',
            sort: 'record_creation_dtsi desc',
            rows: '500',
            fl: 'title_ssi,id,author_ssim,author_display,record_creation_dtsi,cul_doi_ssi,abstract_ssi,author_uni_ssim,subject_ssim,department_ssim,genre_ssim'
          }
        end

        xit 'merges :fq parameter' do
          expect(@controller.repository).to receive(:send_and_receive)
            .with('select', hash_including(expected_params))
            .and_return(empty_response)
          get :index, fq: 'author_uni_ssim:abc123', format: 'rss'
        end
      end
    end
  end

  describe '#custom_results' do
    context 'when :fq in request' do
      let(:uni_filter) { 'author_uni_ssim:abc123' }
      let(:expected_params) do
        {
          qt: 'search',
          fq: [uni_filter, 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
          page: nil,
          q: '',
          sort: 'record_creation_dtsi desc',
          rows: '500',
          fl: 'title_ssi,id,author_ssim,author_display,record_creation_dtsi,cul_doi_ssi,abstract_ssi,author_uni_ssim,subject_ssim,department_ssim,genre_ssim'
        }
      end

      before :each do
        allow(@controller).to receive(:params).and_return(fq: uni_filter)
      end

      xit 'correctly merges :fq parameters' do
        expect(@controller.repository).to receive(:send_and_receive)
          .with('select', expected_params)
          .and_return(empty_response)
        @controller.instance_eval { custom_results }
      end
    end
  end
end
