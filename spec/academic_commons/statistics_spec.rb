require 'rails_helper'

RSpec.describe AcademicCommons::Statistics do
  let(:uni) { 'abc123' }
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
