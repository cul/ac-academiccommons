require 'rails_helper'

RSpec.describe AcademicCommons::Statistics do
  let(:uni) { 'abc123' }
  let(:pid) { 'actest:1' }
  let(:empty_response) { { 'response' => { 'docs' => [] } } }

  let(:statistics) do
    class_rig = Class.new
    class_rig.class_eval do
      include AcademicCommons::Statistics
      def params; Hash.new; end
      def current_user; nil; end
    end
    class_rig.new
  end

  describe '.send_authors_reports' do
    let(:test_params) do
      {
        include_zeroes: true,
        year: Date.current.strftime('%Y'),
        month: Date.current.strftime('%b'),
      }
    end
    let(:author_search) do
      {
        rows: 100_000, sort: 'title_ssi asc', q: nil, page: 1,
        fq: ['author_uni_ssim:"abc123"', 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
        fl: 'title_ssi,id,cul_doi_ssi,doi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
      }
    end

    before :each do
      FactoryBot.create_list(:view_stat, 5)
      allow(statistics).to receive(:params).and_return(test_params)
      allow(Blacklight.default_index).to receive(:search)
        .with(author_search).and_return(author_docs)
      authors = [ { id: 'abc123', email: 'abc123@columbia.edu' } ]
      statistics.instance_eval{ send_authors_reports(authors, nil) }
    end

    subject { ActionMailer::Base.deliveries.pop }

    context 'sends email' do
      let(:author_docs) do
        Blacklight::Solr::Response.new(
          {
            'response' => {
               'docs' => [
                 { 'id' => pid, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                   'cul_doi_ssi' => '', 'doi' => '', 'genre_ssim' => '' },
               ]
            }
          }, {}
        )
      end

      it 'to correct author' do
        expect(subject.to).to contain_exactly 'abc123@columbia.edu'
      end

      it 'with expected subject' do
        expect(subject.subject).to eql "Academic Commons Monthly Download Report for #{test_params[:month]} #{test_params[:year]}"
      end

      it 'with appropriate title' do
        expect(subject.body.to_s).to match /Usage Statistics for abc123/
      end

      it 'with correct documents' do
        expect(subject.body.to_s).to match /First Test Document/
      end
    end

    context 'when all items embargoed' do
      let(:author_docs) do
        Blacklight::Solr::Response.new(
          {
            'response' => {
               'docs' => [
                 { 'id' => pid, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                   'cul_doi_ssi' => '', 'doi' => '', 'genre_ssim' => '', 'free_to_read_start_date_ssi' => Date.tomorrow.strftime('%Y-%m-%d') },
               ]
            }
          }, {}
        )
      end

      it 'does not send an email' do
        expect(subject).to be nil
      end
    end
  end

  describe '.query_to_facets' do
    context 'when querying by two facets' do
      let(:fq) { ['{!raw f=Bears}Polar Bears', '{!raw f=Birds}Hummingbird'] }

      it 'creates correct query' do
        arg = [['Bears', ['Polar Bears']], ['Birds', ['Hummingbird']]]
        expect(
          statistics.instance_eval{ query_to_facets(arg) }
        ).to eq fq
      end
    end

    context 'when querying by one facet' do
      let(:fq) { ['{!raw f=Bears}Polar Bears'] }

      it 'creates correct query' do
        args = [['Bears', ['Polar Bears', 'Black Bear']]]
        expect(
          statistics.instance_eval{ query_to_facets(args) }
        ).to eq fq
      end

      it 'ignores query with no facet_item' do
        args = [['Bears', ['Polar Bears']], ['Birds', [nil]]]
        expect(
          statistics.instance_eval{ query_to_facets(args) }
        ).to eq fq
      end
    end
  end

  describe '.facet_items' do
    it 'creates correct solr query' do
      empty_response = Blacklight::Solr::Response.new(
        { 'response' => { 'docs' => [] }, 'facet_counts' => { 'facet_fields' => { 'author_ssim' => [] } } }, {}
      )
      solr_params = { q: '', :rows => 0, 'facet.limit' => -1, 'facet.field' => ['author_ssim'] }
      expect(Blacklight.default_index).to receive(:search).with(solr_params).and_return(empty_response)
      statistics.instance_eval { facet_items('author_ssim') }
    end
  end

  describe '#detail_report_solr_params' do
    context 'searching by facet' do
      it 'makes correct solr request' do
        params = statistics.instance_eval { detail_report_solr_params('author_uni_ssim', 'xyz123') }
        expect(params).to match(q: nil, fq: ['author_uni_ssim:"xyz123"'], sort: 'title_ssi asc')
      end
    end

    context 'searching by query' do
      it 'makes correct solr request' do
        params = statistics.instance_eval { detail_report_solr_params('search_query', 'q=xyz123&sort=author_sort+asc') }
        expect(params).to match(q: 'xyz123', fq: [], sort: 'author_sort asc')
      end
    end
  end
end
