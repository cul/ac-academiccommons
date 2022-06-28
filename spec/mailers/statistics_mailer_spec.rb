require 'rails_helper'

RSpec.describe StatisticsMailer, type: :mailer do
  describe '.author_monthly' do
    let(:uni) { 'abc123' }
    let(:solr_request) { { q: nil, fq: ["author_uni_ssim:\"#{uni}\""] } }
    let(:solr_params) do
      {
        rows: 100_000, sort: 'title_sort asc', q: nil, page: 1,
        fq: ["author_uni_ssim:\"#{uni}\"", 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
        fl: 'title_ssi,id,cul_doi_ssi,fedora3_pid_ssi,publisher_doi_ssi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
      }
    end
    let(:solr_response) do
      Blacklight::Solr::Response.new(
        {
          'response' => {
            'docs' => [
              { 'id' => 'actest:1', 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                'cul_doi_ssi' => 'http://dx.doi.org/10.7916/TESTDOC1', 'doi' => '', 'genre_ssim' => '' }
            ]
          }
        }, {}, { blacklight_config: Blacklight::Configuration.new }
      )
    end
    let(:usage_stats) do
      AcademicCommons::Metrics::UsageStatistics.new(
        solr_params: solr_request,
        start_date: Date.new(2017, 1, 1).in_time_zone, end_date: Date.new(2017, 1, 31).in_time_zone
      ).calculate_lifetime.calculate_period
    end
    let(:mail) do
      StatisticsMailer.author_monthly('abc123@columbia.edu', 'abc123', usage_stats, '')
    end

    before do
      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'contains correct unsubscribe link' do
      expect(mail.body.to_s).to have_link(
        'click here',
        href: unsubscribe_monthly_url(author_id: 'abc123', chk: Rails.application.message_verifier(:unsubscribe).generate('abc123'))
      )
    end
  end
end
