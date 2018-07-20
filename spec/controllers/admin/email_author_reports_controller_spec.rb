require 'rails_helper'

describe Admin::EmailAuthorReportsController, type: :controller do
  describe 'GET all_author_monthlies' do
    include_examples 'authorization required' do
      let(:http_request) { get :new }
    end

    # context 'when admin user makes request' do
    #   include_context 'admin user'
    #
    #   let(:all_authors_search) do
    #     { rows: 100000, page: 1, fl: "author_uni_ssim" }
    #   end
    #
    #   let(:authors) do
    #     { 'response' => { 'docs' => [ { author_uni_ssim: 'abc123' }] } }
    #   end
    #
    #   let(:author_search) do
    #     {
    #       :rows => 100000, sort: 'title_ssi asc', q: nil, :page => 1,
    #       :fq => "author_uni_ssim:\"author_uni_ssim:abc123\"", fl: "title_ssi,id,cul_doi_ssi,doi,genre_ssim"
    #     }
    #   end
    #   let(:author_docs) do
    #     {
    #       'response' => {
    #         'docs' => [
    #           { 'id' => pid, 'title_ssi' => 'First Test Document',
    #             'cul_doi_ssi' => '', 'doi' => '', 'genre_ssim' => '' },
    #         ]
    #       }
    #     }
    #   end
    #
    #   before :each do
    #     allow(Blacklight.default_index).to receive(:search)
    #       .with(all_authors_search).and_return(authors)
    #     allow(Blacklight.default_index).to receive(:search)
    #       .with(author_search).and_return(author_docs)
    #   end
    #
    #   context 'sending monthly emails to authors' do
    #     let(:email) { ActionMailer::Base.deliveries.pop }
    #     before :each do
    #       get :all_author_monthlies, commit: 'Send To Authors'
    #     end
    #
    #     it 'emails correct author email' do
    #       expect(email.to).to eql "abc123@columbia.edu"
    #     end
    #
    #     it 'email contains correct documents'
    #     it 'email contains correct stats'
    #   end
    # end
  end
end
