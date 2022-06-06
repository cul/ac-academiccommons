require 'rails_helper'

describe EmailAuthorReportsForm, type: :model do
  describe '#send_authors_reports' do
    subject(:email) { ActionMailer::Base.deliveries.pop }

    let(:params) do
      {
        year: Date.current.strftime('%Y'), month: Date.current.strftime('%b'),
        reports_for: 'one', uni: 'abc123', order_works_by: 'Title', deliver: 'reports_to_each_author'
      }
    end

    let(:author_search) do
      {
        rows: 100_000, sort: 'title_sort asc', q: nil, page: 1,
        fq: ['author_uni_ssim:"abc123"', 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
        fl: 'title_ssi,id,cul_doi_ssi,fedora3_pid_ssi,publisher_doi_ssi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
      }
    end

    before do
      FactoryBot.create_list(:view_stat, 5)
      allow(Blacklight.default_index).to receive(:search).with(any_args).and_call_original
      allow(Blacklight.default_index).to receive(:search).with(author_search).and_return(author_docs)
      EmailAuthorReportsForm.new(params).send_emails
    end

    context 'sends email' do
      let(:author_docs) do
        Blacklight::Solr::Response.new(
          {
            'response' => {
              'docs' => [
                { 'id' => '10.7916/ALICE', 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                  'cul_doi_ssi' => '10.7916/ALICE', 'fedora3_pid_ssi' => 'actest:1', 'publisher_doi_ssi' => '', 'genre_ssim' => '' }
              ]
            }
          }, {}, { blacklight_config: Blacklight::Configuration.new }
        )
      end

      it 'to correct author' do
        expect(email.to).to contain_exactly 'abc123@columbia.edu'
      end

      it 'with expected subject' do
        expect(email.subject).to eql "Academic Commons Monthly Download Report for #{params[:month]} #{params[:year]}"
      end

      it 'with appropriate title' do
        expect(email.html_part.body).to match(/Usage Statistics for abc123/)
      end

      it 'with correct documents' do
        expect(email.html_part.body).to match(/First Test Document/)
      end
    end

    context 'when all items embargoed' do
      let(:author_docs) do
        Blacklight::Solr::Response.new(
          {
            'response' => {
              'docs' => [
                { 'id' => 'actest:1', 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A', 'fedora3_pid_ssi' => 'actest:1',
                  'cul_doi_ssi' => '10.7916/ALICE', 'doi' => '', 'genre_ssim' => '', 'free_to_read_start_date_ssi' => Date.tomorrow.strftime('%Y-%m-%d') }
              ]
            }
          }, {}, { blacklight_config: Blacklight::Configuration.new }
        )
      end

      it 'does not send an email' do
        expect(email).to be nil
      end
    end
  end
end
