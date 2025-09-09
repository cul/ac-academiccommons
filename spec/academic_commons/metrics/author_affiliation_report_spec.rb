require 'rails_helper'

RSpec.describe AcademicCommons::Metrics::AuthorAffiliationReport do
  let(:solr_response) do
    wrap_solr_response_data(
      'response' => {
        'docs' => [
          { 'id' => '10.7916/ALICE', 'cul_doi_ssi' => '10.7916/ALICE', 'object_state_ssi' => 'A' },
          { 'id' => '10.7916/PRIDE', 'cul_doi_ssi' => '10.7916/PRIDE', 'object_state_ssi' => 'A' },
        ]
      }
    )
  end

  let(:solr_doc_alice) do
    wrap_solr_response_data(
      'response' => {
        'docs' => [
          { 'id' => '10.7916/ALICE', 'cul_doi_ssi' => '10.7916/ALICE',
            'title_ssi' => 'Alice\'s Adventures in Wonderland',
            'author_uni_ssim' => ['abc123', 'xyz567'], 'object_state_ssi' => 'A',
            'department_ssim' => ['English Department', 'Creative Writing Department'],
            'genre_ssim' => ['Books'], 'fedora3_pid_ssi' => 'actest:6',
            'system_create_dtsi' => '2016-11-21T13:03:42Z',
            }
        ]
      }
    )
  end

  let(:solr_doc_pride) do
    wrap_solr_response_data(
      'response' => {
        'docs' => [
          { 'id' => '10.7916/PRIDE', 'cul_doi_ssi' => '10.7916/PRIDE',
            'title_ssi' => 'Pride and Prejudice',
            'author_uni_ssim' => ['xyz567'], 'object_state_ssi' => 'A',
            'genre_ssim' => ['Books'], 'fedora3_pid_ssi' => 'actest:7',
            'author_ssim' => ['Austen, Jane', 'Doe, Jane'],
            'system_create_dtsi' => '2016-11-21T10:43:15Z'
            }
        ]
      }
    )
  end

  before :each do
    FactoryBot.create(:view_stat, identifier: '10.7916/ALICE')
    FactoryBot.create(:download_stat, identifier: '10.7916/PRIDE')

    allow(Blacklight.default_index).to receive(:search).with({ fq: ['id:"10.7916/ALICE"'], qt: 'search', rows: 100_000 }).and_return(solr_doc_alice)
    allow(Blacklight.default_index).to receive(:search).with({ fq: ['id:"10.7916/PRIDE"'], qt: 'search', rows: 100_000 }).and_return(solr_doc_pride)
    allow(Blacklight.default_index).to receive(:search).with({
      rows: 100_000, page: 1, q: nil, sort: 'title_sort asc', fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
      fl: 'title_ssi,id,cul_doi_ssi,fedora3_pid_ssi,publisher_doi_ssi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
    }).and_return(solr_response)

    ldap = instance_double('Cul::LDAP')
    allow(Cul::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:find_by_uni).with('xyz567').and_return(
      instance_double('Cul::LDAP::Entry', uni: 'xyz567', name: 'Jane Austen', title: 'Professor of English', organizational_unit: 'English Department')
    )
    allow(ldap).to receive(:find_by_uni).with('abc123').and_return(
      instance_double('Cul::LDAP::Entry', uni: 'abc123', name: 'Lewis Carroll', title: 'Professor of Creative Writing', organizational_unit: 'English Department')
    )
  end

  subject { AcademicCommons::Metrics::AuthorAffiliationReport.generate_csv }

  context 'generates' do
    let(:expected_csv) do
      [
        ['doi', 'legacy id', 'lifetime downloads', 'lifetime views', 'department ac', 'genre', 'creation date', 'multi-author count', 'author uni', 'author name', 'ldap author title', 'ldap organizational unit'],
        ['10.7916/ALICE', 'actest:6', '0', '1', 'English Department, Creative Writing Department', 'Books', '2016-11-21T13:03:42Z', '1', 'abc123', 'Lewis Carroll', 'Professor of Creative Writing', 'English Department'],
        ['10.7916/ALICE', 'actest:6', '0', '1', 'English Department, Creative Writing Department', 'Books', '2016-11-21T13:03:42Z', '2', 'xyz567', 'Jane Austen', 'Professor of English', 'English Department'],
        ['10.7916/PRIDE', 'actest:7', '0', '0', '', 'Books', '2016-11-21T10:43:15Z', '1', 'xyz567', 'Jane Austen', 'Professor of English', 'English Department'],
        ['10.7916/PRIDE', 'actest:7', '0', '0', '', 'Books', '2016-11-21T10:43:15Z', '2', nil, nil, nil, nil]
      ]
    end

    it 'expected csv' do
      expect(CSV.parse(subject)[3..]).to match expected_csv
    end
  end
end
