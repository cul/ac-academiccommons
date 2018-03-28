require 'rails_helper'

describe 'GET /api/v1/data_feed/:key', type: :request do
   context 'when known key is given' do
     it 'should return 200' do
       get '/api/v1/data_feed/masters'
       expect(response.status).to be 200
     end

     context 'if no record match feed' do
       it 'returns feed with no records' do
         get '/api/v1/data_feed/masters'
         expect(JSON.load(response.body)).to match({
           'records' => [],
           'total_number_of_results' => 0,
         })
       end
     end

     context 'if records match feed' do
       let(:connection) { double }
       let(:parameters) do
         {
           q: nil, sort: nil, start: 0, rows: 100000,
           fq: ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\"", 'genre_facet:"Theses"', 'degree_level_name_ssim:"Master\'s"'],
           fl: '*', qt: 'search'
         }
       end

       let(:solr_response) do
         {
           'response' => {
             'numFound' => 1,
             'docs' => [
               {
                 'id' => 'actest:9',
                 'record_creation_date' => '2011-02-25T18:57:00Z',
                 'record_change_date' => '2011-02-25T18:57:00Z',
                 'language' => 'English',
                 'date_issued' => '2009',
                 'handle' => '10.7916/D8WS9153',
                 'title_display' => 'The Warburg effect and its role in cancer detection and therapy',
                 'author_info' => ['Christ, Ethan J. : ec2038 :'],
                 'author_facet' => ['Christ, Ethan J.'],
                 'author_display' => 'Christ, Ethan J.',
                 'pub_date_facet' => ['2009'],
                 'genre_facet' => ['Theses'],
                 'abstract' => 'The Warburg effect is a cellular phenomenon in cancer cells...',
                 'subject_facet' => ['Biology'],
                 'type_of_resource_mods' => ['text'],
                 'type_of_resource_facet' => ['Text'],
                 'organization_facet' => ['Columbia University'],
                 'department_facet' => ['Biotechnology'],
                 'degree_name_ssim' => ['M.S.'],
                 'degree_grantor_ssim' => ['Columbia University'],
                 'degree_level_ssim' => ['1'],
                 'degree_level_name_ssim' => ['Master\'s'],
                 'degree_name_ssim' => ['M.S.'],
                 'degree_grantor_ssim': ['Columbia University'],
                 'degree_discipline_ssim': ['Biotechnology'],
                 'degree_level_ssim': ['1'],
                 'degree_level_name_ssim': ['Master\'s'],
                 'notes' => ['M.S. Columbia University'],
                 'free_to_read_start_date' => '2018-01-01',
                 'thesis_advisor': ['Smith, John']
               }
             ]
           }
         }
       end

       before do
         allow(AcademicCommons::Utils).to receive(:rsolr).and_return(connection)
       end

       it 'returns matching records' do
         allow(connection).to receive(:get).with('select', { params: parameters }).and_return(solr_response)

         get '/api/v1/data_feed/masters'

         expect(JSON.load(response.body)).to match({
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
               'created_at' => '2011-02-25T18:57:00Z',
               'modified_at' => '2011-02-25T18:57:00Z',
               'columbia_series' => [],
               'thesis_advisor' => ['Smith, John'],
               'degree_name' => 'M.S.',
               'degree_level' => 'Master\'s',
               'degree_grantor' => 'Columbia University',
               'degree_discipline' => 'Biotechnology',
               'embargo_end' => '2018-01-01',
               'notes' => 'M.S. Columbia University',
             }
           ]
         })
       end
     end
   end

   context 'when unknown key is given' do
     it 'should return 400' do
       get '/api/v1/data_feed/undefined_key'
       expect(response.status).to be 400
     end
   end
end
