require 'rails_helper'

describe 'GET /api/v1/record/doi/:doi', type: :request do
  context 'when doi correct' do
    before { get '/api/v1/record/doi/10.7916/ALICE' }

    let(:expected_json) do
      {
        'abstract' => 'Background -  Alice is feeling bored and drowsy while sitting on the riverbank with her older sister, who is reading a book with no pictures or conversations.',
        'author' => ['Carroll, Lewis', 'Weird Old Guys.'],
        'columbia_series' => [],
        'created_at' => '2017-09-14T16:31:33Z',
        'date' => '1865',
        'degree_discipline' => nil,
        'degree_grantor' => nil,
        'degree_level' => nil,
        'degree_name' => nil,
        'department' => ['Bucolic Literary Society.'],
        'embargo_end' => nil,
        'id' => '10.7916/ALICE',
        'language' => ['English'],
        'legacy_id' => 'actest:1',
        'modified_at' => '2017-09-14T16:48:05Z',
        'notes' => nil,
        'persistent_url' => 'https://doi.org/10.7916/ALICE',
        'resource_paths' => ['/doi/10.7916/TESTDOC2/download', '/doi/10.7916/TESTDOC3/download', '/doi/10.7916/TESTDOC4/download'],
        'subject' => ['Tea Parties', 'Wonderland', 'Rabbits', 'Magic', 'Nonsense literature', 'Bildungsromans'],
        'thesis_advisor' => [],
        'title' => 'Alice\'s Adventures in Wonderland',
        'type' => ['Articles']
      }
    end

    it 'returns 200' do
      expect(response.status).to be 200
    end

    it 'returns response body with correct record information' do
      expect(JSON.parse(response.body)).to match(expected_json)
    end
  end

  context 'when doi incorrect' do
    before { get '/api/v1/record/doi/10.48472/KDF84' }

    it 'returns 404' do
      expect(response.status).to be 404
    end
  end
end
