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
        year: Date.today.strftime("%Y"),
        month: Date.today.strftime("%b"),
      }
    end
    let(:author_search) do
      {
        rows: 100000, sort: 'title_display asc', q: nil, page: 1,
        fq: "author_uni:\"abc123\"", fl: "title_display,id,handle,doi,genre_facet,record_creation_date"
      }
    end
    let(:author_docs) do
      {
        'response' => {
          'docs' => [
            { 'id' => pid, 'title_display' => 'First Test Document',
              'handle' => '', 'doi' => '', 'genre_facet' => '' },
          ]
        }
      }
    end

    before :each do
      FactoryGirl.create_list(:view_stat, 5)
      allow(statistics).to receive(:params).and_return(test_params)
      allow(Blacklight.default_index).to receive(:search)
        .with(author_search).and_return(author_docs)
      authors = [ { id: 'abc123', email: 'abc123@columbia.edu' } ]
      statistics.instance_eval{ send_authors_reports(authors, nil) }
    end

    context 'sends email' do
      let(:email) { ActionMailer::Base.deliveries.pop }

      it 'to correct author' do
        expect(email.to).to contain_exactly 'abc123@columbia.edu'
      end

      it 'with expected subject' do
        expect(email.subject).to eql "Academic Commons Monthly Download Report for #{test_params[:month]} #{test_params[:year]}"
      end

      it 'with appropriate title' do
        expect(email.body.to_s).to match /Usage Statistics for abc123/
      end

      it 'with correct documents' do
        expect(email.body.to_s).to match /First Test Document/
      end
    end
  end

  describe ".query_to_facets" do
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
        { 'response' => { 'docs' => [] }, 'facet_counts' => { 'facet_fields' => { 'author_facet' => [] } } }, {}
      )
      solr_params = { :q => "", :rows => 0, 'facet.limit' => -1, 'facet.field' => ['author_facet'] }
      expect(Blacklight.default_index).to receive(:search).with(solr_params).and_return(empty_response)
      statistics.instance_eval { facet_items('author_facet') }
    end
  end

  describe '#detail_report_solr_params' do
    context 'searching by facet' do
      it 'makes correct solr request' do
        params = statistics.instance_eval { detail_report_solr_params('author_uni', 'xyz123') }
        expect(params).to match(q: nil, fq: 'author_uni:"xyz123"', sort: "title_display asc")
      end
    end

    context 'searching by query' do
      let(:test_params) { { 'f' => 'department_facet:Columbia College', 'q' => '', 'sort' => 'author_sort asc'} }

      before :each do
        allow(statistics).to receive(:parse_search_query).and_return(test_params)
      end

      it 'makes correct solr request' do
        params = statistics.instance_eval { detail_report_solr_params('search_query', 'author_uni=xyz123') }
        expect(params).to match(q: '', fq: 'department_facet:Columbia College', sort: 'author_sort asc')
      end
    end
  end
end
