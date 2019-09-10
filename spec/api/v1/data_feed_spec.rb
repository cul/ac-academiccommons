require 'rails_helper'

describe 'GET /api/v1/data_feed/:key', type: :request do
  context 'when no token is provided' do
    it 'returns 401' do
      get '/api/v1/data_feed/masters'
      expect(response.status).to be 401
    end
  end

  context 'when provides invalid token' do
    let(:headers) { { 'HTTP_AUTHORIZATION' => 'Token token=invalid_token' } }

    before do
      Token.create(scope: Token::DATAFEED, token: 'foobar')
    end

    it 'returns 401' do
      get '/api/v1/data_feed/masters', headers: headers
      expect(response.status).to be 401
    end
  end

  context 'when provides valid token' do
    let(:headers) { { 'HTTP_AUTHORIZATION' => 'Token token=foobar' } }

    before do
      Token.create(scope: Token::DATAFEED, token: 'foobar')
    end

    context 'when known key is given' do
      it 'returns 200' do
        get '/api/v1/data_feed/masters', headers: headers
        expect(response.status).to be 200
      end
    end

    context 'when unknown key is given' do
      it 'returns 400' do
        get '/api/v1/data_feed/undefined_key', headers: headers
        expect(response.status).to be 400
      end
    end

    context 'if no record match feed' do
      it 'returns feed with no records' do
        get '/api/v1/data_feed/masters', headers: headers
        expect(JSON.parse(response.body)).to match(
          'records' => [],
          'total_number_of_results' => 0
        )
      end
    end

    context 'if records match feed' do
      let(:parameters) do
        {
          q: nil, sort: nil, start: 0, rows: 100_000,
          fq: ['genre_ssim:"Theses"', 'degree_level_name_ssim:"Master\'s"', "has_model_ssim:\"#{ContentAggregator.to_class_uri}\""],
          qt: 'search', fl: '*,assets:[subquery]',
          'assets.q': '{!terms f=cul_member_of_ssim v=$row.fedora3_uri_ssi}', 'assets.rows': 100_000
        }
      end

      let(:solr_response) do
        Blacklight::Solr::Response.new({
          'response' => {
            'numFound' => 1,
            'docs' => [
              {
                'id' => '10.7916/D8WS9153',
                'record_creation_dtsi' => '2011-02-25T18:57:00Z',
                'record_change_dtsi' => '2011-02-25T18:57:00Z',
                'object_state_ssi' => 'A',
                'language_ssim' => ['English'],
                'cul_doi_ssi' => '10.7916/D8WS9153',
                'fedora3_pid_ssi' => 'actest:9',
                'title_ssi' => 'The Warburg effect and its role in cancer detection and therapy',
                'author_ssim' => ['Christ, Ethan J.'],
                'pub_date_isi' => '2009',
                'genre_ssim' => ['Theses'],
                'abstract_ssi' => 'The Warburg effect is a cellular phenomenon in cancer cells...',
                'subject_ssim' => ['Biology'],
                'department_ssim' => ['Biotechnology'],
                'degree_grantor_ssim' => ['Columbia University'],
                'degree_level_ssim' => ['1'],
                'degree_level_name_ssim' => ['Master\'s'],
                'degree_name_ssim' => ['M.S.'],
                'degree_discipline_ssim' => ['Biotechnology'],
                'notes_ssim' => ['M.S. Columbia University'],
                'free_to_read_start_date_ssi' => '2018-01-01',
                'thesis_advisor_ssim' => ['Smith, John'],
                'assets' => {
                  'numFound' => 1,
                  'start' => 0,
                  'docs' => [
                    {
                      'id' => '10.7916/D8WS9155',
                      'cul_doi_ssi' => '10.7916/D8WS9155',
                      'active_fedora_model_ssi' => 'GenericResource'
                    }
                  ]
                }
              }
            ]
          }
        }, {})
      end

      let(:json_response) do
        {
          'total_number_of_results' => 1,
          'records' => [
            {
              'id' => '10.7916/D8WS9153',
              'legacy_id' => 'actest:9',
              'title' => 'The Warburg effect and its role in cancer detection and therapy',
              'author' => ['Christ, Ethan J.'],
              'abstract' => 'The Warburg effect is a cellular phenomenon in cancer cells...',
              'date' => '2009',
              'department' => ['Biotechnology'],
              'subject' => ['Biology'],
              'type' => ['Theses'],
              'language' => ['English'],
              'persistent_url' => 'https://doi.org/10.7916/D8WS9153',
              'resource_paths' => ['/doi/10.7916/D8WS9155/download'],
              'created_at' => '2011-02-25T18:57:00Z',
              'modified_at' => '2011-02-25T18:57:00Z',
              'columbia_series' => [],
              'thesis_advisor' => ['Smith, John'],
              'degree_name' => 'M.S.',
              'degree_level' => 'Master\'s',
              'degree_grantor' => 'Columbia University',
              'degree_discipline' => 'Biotechnology',
              'embargo_end' => '2018-01-01',
              'notes' => 'M.S. Columbia University'
            }
          ]
        }
      end

      it 'returns matching records' do
        allow(Blacklight.default_index).to receive(:search).with(parameters).and_return(solr_response)

        get '/api/v1/data_feed/masters', headers: headers

        expect(JSON.parse(response.body)).to match(json_response)
      end
    end
  end
end
