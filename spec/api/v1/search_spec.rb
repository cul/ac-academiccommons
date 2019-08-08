require 'rails_helper'

describe 'GET /api/v1/search', type: :request do
  let(:connection) { double }
  let(:empty_response) { Blacklight::Solr::Response.new({ 'response' => { 'docs' => [] } }, {}) }
  let(:base_parameters) do
    {
      qt: 'search', fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
      rows: 25, q: nil, sort: 'score desc, pub_date_isi desc, title_sort asc',
      start: 0, facet: true,
      'facet.field': ['author_ssim', 'pub_date_isi', 'department_ssim', 'subject_ssim', 'genre_ssim', 'series_ssim'],
      'facet.limit': 5
    }
  end

  context 'applies query' do
    let(:parameters) { base_parameters.merge(q: 'alice') }

    it 'creates correct solr query' do
      expect(Blacklight.default_index).to receive(:search).with(parameters).and_return(empty_response)
      get '/api/v1/search?q=alice'
    end
  end

  context 'applies filters' do
    context 'by departments' do
      let(:parameters) do
        base_parameters.merge(
          fq: ['department_ssim:"Computer Science"', 'department_ssim:"Bioinformatics"', 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"']
        )
      end

      it 'creates correct solr query' do
        expect(Blacklight.default_index).to receive(:search).with(parameters).and_return(empty_response)
        get '/api/v1/search?department[]=Computer+Science&department[]=Bioinformatics'
      end
    end

    context 'by author' do
      let(:parameters) do
        base_parameters.merge(
          fq: ['author_ssim:"Carroll, Lewis"', 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"']
        )
      end

      it 'creates correct solr query' do
        expect(Blacklight.default_index).to receive(:search).with(parameters).and_return(empty_response)
        get '/api/v1/search?author[]=Carroll,+Lewis'
      end
    end

    context 'by author id' do
      let(:parameters) do
        base_parameters.merge(
          fq: ['author_uni_ssim:"abc123"', 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"']
        )
      end

      it 'creates correct solr query' do
        expect(Blacklight.default_index).to receive(:search).with(parameters).and_return(empty_response)
        get '/api/v1/search?author_id[]=abc123'
      end
    end
  end

  context 'applies search_type' do
    let(:parameters) do
      base_parameters.merge(
        'spellcheck.dictionary': 'title', qf: '${title_qf}', pf: '${title_pf}'
      )
    end

    it 'creates correct solr query' do
      expect(Blacklight.default_index).to receive(:search).with(parameters).and_return(empty_response)
      get '/api/v1/search?search_type=title'
    end

    it 'returns error if invalid search type' do
      get '/api/v1/search?search_type=foobar'
      expect(response.status).to be 400
      expect(JSON.parse(response.body)).to match(
        'error' => 'search_type does not have a valid value'
      )
    end
  end

  context 'applies sort order' do
    let(:parameters) { base_parameters.merge(sort: 'title_sort asc, pub_date_isi desc') }

    it 'creates correct solr query' do
      expect(Blacklight.default_index).to receive(:search).with(parameters).and_return(empty_response)
      get '/api/v1/search?sort=title&order=asc'
    end

    it 'returns error if invalid sort' do
      get '/api/v1/search?sort=foobar'
      expect(response.status).to be 400
      expect(JSON.parse(response.body)).to match(
        'error' => 'sort does not have a valid value'
      )
    end
  end

  context 'paginates' do
    let(:parameters) { base_parameters.merge(start: 50) }

    it 'creates correct solr query' do
      expect(Blacklight.default_index).to receive(:search).with(parameters).and_return(empty_response)
      get '/api/v1/search?page=3'
    end

    it 'returns error if page is not a number' do
      get '/api/v1/search?page=foo'
      expect(response.status).to be 400
      expect(JSON.parse(response.body)).to match(
        'error' => 'page is invalid, page does not have a valid value'
      )
    end
  end

  context 'when searching and filtering by multiple filters' do
    before { get '/api/v1/search?type[]=Articles&date[]=1865' }
    let(:expected_json) do
      {
        'total_number_of_results' => 1,
        'page' => 1,
        'params' => { 'q' => nil, 'sort' => 'best_match', 'order' => 'desc', 'search_type' => 'keyword', 'filters' => { 'date' => ['1865'], 'type' => ['Articles'] } },
        'per_page' => 25,
        'records' => [
          {
            'id' => '10.7916/ALICE',
            'legacy_id' => 'actest:1',
            'title' => 'Alice\'s Adventures in Wonderland',
            'author' => ['Carroll, Lewis', 'Weird Old Guys.'],
            'abstract' => 'Background -  Alice is feeling bored and drowsy while sitting on the riverbank with her older sister, who is reading a book with no pictures or conversations.',
            'date' => '1865',
            'department' => ['Bucolic Literary Society.'],
            'subject' => ['Tea Parties', 'Wonderland', 'Rabbits', 'Magic', 'Nonsense literature', 'Bildungsromans'],
            'type' => ['Articles'],
            'language' => ['English'],
            'persistent_url' => 'https://doi.org/10.7916/ALICE',
            'created_at' => '2017-09-14T16:31:33Z',
            'modified_at' => '2017-09-14T16:48:05Z'
          }
        ],
        'facets' => {
          'author' => { 'Carroll, Lewis' => 1, 'Weird Old Guys.' => 1 },
          'date' => { '1865' => 1 }, 'department' => { 'Bucolic Literary Society.' => 1 },
          'subject' => { 'Bildungsromans' => 1, 'Nonsense literature' => 1, 'Rabbits' => 1, 'Magic' => 1, 'Tea Parties' => 1 },
          'type' => { 'Articles' => 1 }
        }
      }
    end

    it 'returns correct json response' do
      expect(JSON.parse(response.body)).to match expected_json
    end
  end

  context 'applies per_page' do
    let(:parameters) { base_parameters.merge(rows: 50) }

    it 'returns an error if greater than 100' do
      get '/api/v1/search?per_page=101'
      expect(response.status).to be 400
      expect(JSON.parse(response.body)).to match(
        'error' => 'per_page does not have a valid value'
      )
    end

    it 'creates correct solr query' do # when per_page is something other than the default
      expect(Blacklight.default_index).to receive(:search).with(parameters).and_return(empty_response)
      get '/api/v1/search?per_page=50'
    end
  end
end
