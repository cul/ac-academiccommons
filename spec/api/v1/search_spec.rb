require 'rails_helper'

describe 'GET /api/v1/search', type: :request do
  let(:connection) { double }
  let(:empty_response) { { 'response' => { 'docs' => [] } } }
  let(:base_parameters) do
    {
      q: nil, sort: 'score desc, pub_date_isi desc, title_sort asc',
      start: 0, rows: 25,
      fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
      fl: '*', qt: 'search', facet: 'true',
      'facet.field' => ['author_ssim', 'pub_date_isi', 'department_ssim', 'subject_ssim', 'genre_ssim', 'series_ssim'],
      'f.author_ssim.limit' => 5, 'f.pub_date_isi.limit' => 5,
      'f.department_ssim.limit' => 5, 'f.subject_ssim.limit' => 5,
      'f.genre_ssim.limit' => 5, 'f.series_ssim.limit' => 5
    }
  end

  context 'applies query' do
    let(:parameters) { base_parameters.merge(q: 'alice') }

    it 'creates correct solr query' do
      allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
      expect(connection).to receive(:get).with('select', params: parameters).and_return(empty_response)
      get '/api/v1/search?format=rss&q=alice'
    end
  end

  context 'applies filters' do
    context 'by departments' do
      let(:parameters) do
        base_parameters.merge(
          fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"', 'department_ssim:"Computer Science"', 'department_ssim:"Bioinformatics"']
        )
      end

      it 'creates correct solr query' do
        allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
        expect(connection).to receive(:get).with('select', params: parameters).and_return(empty_response)
        get '/api/v1/search?department[]=Computer+Science&department[]=Bioinformatics'
      end
    end

    context 'by author' do
      let(:parameters) do
        base_parameters.merge(
          fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"', 'author_ssim:"Carroll, Lewis"']
        )
      end

      it 'creates correct solr query' do
        allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
        expect(connection).to receive(:get).with('select', params: parameters).and_return(empty_response)
        get '/api/v1/search?author[]=Carroll,+Lewis'
      end
    end

    context 'by author id' do
      let(:parameters) do
        base_parameters.merge(
          fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"', 'author_uni_ssim:"abc123"']
        )
      end

      it 'creates correct solr query' do
        allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
        expect(connection).to receive(:get).with('select', params: parameters).and_return(empty_response)
        get '/api/v1/search?format=rss&author_id[]=abc123'
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
      allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
      expect(connection).to receive(:get).with('select', params: parameters).and_return(empty_response)
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
      allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
      expect(connection).to receive(:get).with('select', params: parameters).and_return(empty_response)
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
      allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
      expect(connection).to receive(:get).with('select', params: parameters).and_return(empty_response)
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
          'subject' => { 'Bildungsromans' => 1, 'Nonsense literature' => 1, 'Rabbits' => 1, 'Magic' => 1, 'Tea Parties' => 1, 'Wonderland' => 1 },
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
      allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
      expect(connection).to receive(:get).with('select', params: parameters).and_return(empty_response)
      get '/api/v1/search?per_page=50'
    end
  end

  context 'searches and returns rss' do
    let(:expected_xml) do
      '<?xml version="1.0" encoding="UTF-8"?>
        <rss xmlns:dc="http://purl.org/dc/elements/1.1" xmlns:vivo="http://vivoweb.org/ontology/core" version="2.0">
        <channel>
          <title>Academic Commons Search Results</title>
          <link>http://www.example.com/api/v1/search?format=rss&amp;q=alice</link>
          <description>Academic Commons Search Results</description>
          <language>en-us</language>
          <item>
            <title>Alice\'s Adventures in Wonderland</title>
            <link>https://doi.org/10.7916/ALICE</link>
            <dc:creator>Carroll, Lewis; Weird Old Guys.</dc:creator>
            <guid>https://doi.org/10.7916/ALICE</guid>
            <pubDate>Thu, 14 Sep 2017 12:31:33 -0400</pubDate>
            <dc:date>1865</dc:date>
            <description>Background -  Alice is feeling bored and drowsy while sitting on the riverbank with her older sister, who is reading a book with no pictures or conversations.</description>
            <dc:subject>Tea Parties, Wonderland, Rabbits, Magic, Nonsense literature, Bildungsromans</dc:subject>
            <dc:type>Articles</dc:type>
            <vivo:Department>Bucolic Literary Society.</vivo:Department>
          </item>
       </channel>
     </rss>'
    end

    it 'returns correct rss feed' do
      get '/api/v1/search?format=rss&q=alice'
      expect(Nokogiri::XML(response.body)).to be_equivalent_to expected_xml
    end
  end
end
