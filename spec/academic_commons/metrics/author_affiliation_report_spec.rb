require 'rails_helper'

RSpec.describe AcademicCommons::Metrics::AuthorAffiliationReport do
  let(:solr_response) do
    Blacklight::Solr::Response.new(
      {
        'response' => {
          'docs' => [
            { 'id' => '10.7916/ALICE', 'cul_doi_ssi' => '10.7916/ALICE', 'object_state_ssi' => 'A' },
            { 'id' => '10.7916/PRIDE', 'cul_doi_ssi' => '10.7916/PRIDE', 'object_state_ssi' => 'A' },
          ]
        }
      },
      {})
  end

  let(:solr_doc_alice) do
    Blacklight::Solr::Response.new({
      'response' => {
        'docs' => [
          { 'id' => '10.7916/ALICE', 'cul_doi_ssi' => '10.7916/ALICE',
            'title_ssi' => 'Alice\'s Adventures in Wonderland',
            'author_uni_ssim' => ['abc123', 'xyz567'], 'object_state_ssi' => 'A',
            'department_ssim' => ['English Department', 'Creative Writing Department'],
            'genre_ssim' => ['Books'],
            'system_create_dtsi' => '2016-11-21T13:03:42Z',
            }
        ]
      }
    }, {})
  end

  let(:solr_doc_pride) do
    Blacklight::Solr::Response.new({
      'response' => {
        'docs' => [
          { 'id' => '10.7916/PRIDE', 'cul_doi_ssi' => '10.7916/PRIDE',
            'title_ssi' => 'Pride and Prejudice',
            'author_uni_ssim' => ['xyz567'], 'object_state_ssi' => 'A',
            'genre_ssim' => ['Books'],
            'author_ssim' => ['Austen, Jane', 'Doe, Jane'],
            'system_create_dtsi' => '2016-11-21T10:43:15Z'
            }
        ]
      }
    }, {})
  end

  before :each do
    FactoryBot.create(:view_stat, identifier: '10.7916/ALICE')
    FactoryBot.create(:download_stat, identifier: '10.7916/PRIDE')

    allow(Blacklight.default_index).to receive(:search).with(any_args).and_return(solr_response)
    allow(Blacklight.default_index).to receive(:find).with('10.7916/ALICE').and_return(solr_doc_alice)
    allow(Blacklight.default_index).to receive(:find).with('10.7916/PRIDE').and_return(solr_doc_pride)
    allow(AcademicCommons::LDAP).to receive(:find_by_uni).with('xyz567').and_return(
      OpenStruct.new(uni: 'xyz567', name: 'Jane Austen', title: 'Professor of English', organizational_unit: 'English Department')
    )
    allow(AcademicCommons::LDAP).to receive(:find_by_uni).with('abc123').and_return(
      OpenStruct.new(uni: 'abc123', name: 'Lewis Carroll', title: 'Professor of Creative Writing', organizational_unit: 'English Department')
    )
  end

  subject { AcademicCommons::Metrics::AuthorAffiliationReport.generate_csv }

  context 'generates' do
    let(:expected_csv) do
      [
        ['pid', 'persistent url', 'lifetime downloads', 'lifetime views', 'department ac', 'genre', 'creation date', 'multi-author count', 'author uni', 'author name', 'ldap author title', 'ldap organizational unit'],
        ['actest:6', 'https://doi.org/10.7916/ALICE', '0', '1', 'English Department, Creative Writing Department', 'Books', '2016-11-21T13:03:42Z', '1', 'abc123', 'Lewis Carroll', 'Professor of Creative Writing', 'English Department'],
        ['actest:6', 'https://doi.org/10.7916/ALICE', '0', '1', 'English Department, Creative Writing Department', 'Books', '2016-11-21T13:03:42Z', '2', 'xyz567', 'Jane Austen', 'Professor of English', 'English Department'],
        ['actest:7', 'https://doi.org/10.7916/PRIDE', '0', '0', '', 'Books', '2016-11-21T10:43:15Z', '1', 'xyz567', 'Jane Austen', 'Professor of English', 'English Department'],
        ['actest:7', 'https://doi.org/10.7916/PRIDE', '0', '0', '', 'Books', '2016-11-21T10:43:15Z', '2', nil, nil, nil, nil]
      ]
    end

    it 'expected csv' do
      pending 'awaiting decision from ACHYDRA-472'
      expect(CSV.parse(subject)[3..-1]).to match expected_csv
    end
  end
end
