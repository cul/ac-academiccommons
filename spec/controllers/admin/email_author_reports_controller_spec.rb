require 'rails_helper'

describe Admin::EmailAuthorReportsController, type: :controller do
  describe 'GET new' do
    include_examples 'authorization required' do
      let(:http_request) { get :new }
    end
  end

  describe 'POST create' do
    context 'when admin user makes request' do
      include_context 'admin user for controller'

      let(:all_authors_search) do
        { qt: 'search', rows: 100_000, fl: 'author_uni_ssim', fq: [] }
      end
      let(:authors) do
        Blacklight::Solr::Response.new(
          { 'response' => { 'docs' => [{ 'author_uni_ssim' => 'abc123' }] } }, {}
        )
      end
      let(:author_search) do
        {
          rows: 100_000, sort: 'title_ssi asc', q: nil, page: 1,
          fq: ['author_uni_ssim:"abc123"', 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
          fl: 'title_ssi,id,cul_doi_ssi,fedora3_pid_ssi,publisher_doi_ssi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
        }
      end
      let(:author_docs) do
        Blacklight::Solr::Response.new(
          {
            'response' => {
              'docs' => [
                {
                  'id' => '10.7916/ALICE', 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                  'cul_doi_ssi' => '10.7916/ALICE', 'fedora3_pid_ssi' => 'actest:1', 'publisher_doi_ssi' => '', 'genre_ssim' => ''
                }
              ]
            }
          },
          {}
        )
      end
      let(:email) { ActionMailer::Base.deliveries.pop }

      before do
        FactoryBot.create_list(:view_stat, 5)
        allow(Blacklight.default_index).to receive(:search).with(all_authors_search).and_return(authors)
        allow(Blacklight.default_index).to receive(:search).with(author_search).and_return(author_docs)

        post :create, params: {
          email_author_reports_form: {
            reports_for: 'all',
            month: Date.current.prev_month.strftime('%b'),
            year: Date.current.prev_month.strftime('%Y'),
            order_works_by: 'titles',
            deliver: 'reports_to_each_author'
          }
        }
      end

      it 'emails correct author email' do
        expect(email.to).to contain_exactly 'abc123@columbia.edu'
      end

      it 'email contains correct documents' do
        expect(email.body.to_s).to match(/First Test Document/)
      end
    end
  end
end
