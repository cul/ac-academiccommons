require 'rails_helper'

RSpec.describe Notifier, type: :mailer do
  describe '.author_monthly' do
    let(:uni) { 'abc123' }
    let(:solr_request) { { q: nil, fq: ["author_uni:\"#{uni}\""] } }
    let(:solr_params) do
      {
        rows: 100_000, sort: 'title_ssi asc', q: nil, page: 1,
        fq: ["author_uni:\"#{uni}\"", 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
        fl: 'title_ssi,id,handle,doi,genre_facet,record_creation_date,object_state_ssi,free_to_read_start_date'
      }
    end
    let(:solr_response) do
      Blacklight::Solr::Response.new(
        {
          'response' => {
            'docs' => [
              { 'id' => 'actest:1', 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                'handle' => 'http://dx.doi.org/10.7916/TESTDOC1', 'doi' => '', 'genre_facet' => '' }
            ]
          }
        }, {}
      )
    end
    let(:usage_stats) { AcademicCommons::Metrics::UsageStatistics.new(solr_request, Date.new(2017, 1, 1), Date.new(2017, 1, 31)) }
    let(:mail) do
      Notifier.author_monthly('abc123@columbia.edu', 'abc123', usage_stats, '')
    end

    before :each do
      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'contains correct unsubscribe link' do
      expect(mail.body.to_s).to have_link('click here', statistics_unsubscribe_monthly_url(author_id: 'abc123', chk: 'abc123'.crypt('xZ')))
    end
  end
end
