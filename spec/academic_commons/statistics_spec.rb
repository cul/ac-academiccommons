require 'rails_helper'

RSpec.describe AcademicCommons::Statistics do
  let(:uni) { 'abc123' }
  let(:pid) { 'actest:1' }
  let(:empty_response) { { 'response' => { 'docs' => [] } } }

  let(:statistics) do
    class_rig = Class.new
    class_rig.class_eval do
      include AcademicCommons::Statistics
      def repository; end
      def params; Hash.new; end
    end
    class_rig.new
  end

  describe '.collect_asset_pids' do
    let(:original_pids) { ['ac:8', 'ac: 2', "ac:3", "ac:a5", "acc:32"] }
    let(:pid_collection) { original_pids.map {|v| { id: v } } }

    context 'download event' do
      let(:event) { Statistic::DOWNLOAD_EVENT }
      let(:collected_pids) { ['ac:9', 'ac:3', 'ac:4', 'ac:1'] }
      before do
        allow(statistics).to receive(:build_resource_list).with(hash_including(:id))
          .and_return([{pid:'ac:9'}],
                     [{pid:'ac:3'}],
                     [{pid:'ac:4'}],
                     [{pid:'ac:1'}], # method expected to dedupe
                     [{pid:'ac:1'},{pid:'acc:33'}]) # method expected to pick first one
      end

      subject { statistics.send :collect_asset_pids, pid_collection, event }

      it { is_expected.to contain_exactly(*collected_pids) }
    end

    context 'non-download event' do
      let(:event) { Statistic::VIEW_EVENT }
      let(:collected_pids) { original_pids }

      subject { statistics.send :collect_asset_pids, pid_collection, event }
      it { is_expected.to contain_exactly(*collected_pids) }
    end
  end

  describe '.get_author_stats', integration: true do
    before do
      allow(statistics).to receive(:repository).and_return(Blacklight.default_index)
    end
    context 'when requesting usage stats for author' do
      let(:solr_params) do
        {
          :rows => 100000, :sort => 'title_display asc', :q => nil,
          :fq => "author_uni:\"author_uni:#{uni}\"", :fl => "title_display,id,handle,doi,genre_facet",
          :page => 1
        }
      end

      let(:solr_response) do
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
        # Add records for a pid view and download
        FactoryGirl.create(:view_stat)
        FactoryGirl.create(:view_stat)
        FactoryGirl.create(:download_stat)
        FactoryGirl.create(:streaming_stat)

        allow(Blacklight.default_index).to receive(:search)
          .with(solr_params).and_return(solr_response)
      end

      context 'when requesting stats for current month' do
        before :each do
          @results, @stats, @totals, @download_ids = statistics.instance_eval{
            get_author_stats(Date.today - 1.month, Date.today,
              "author_uni:abc123", nil, true, 'author_uni', true, nil)
          }
        end

        it 'returns correct results' do
          expect(@results).to eq solr_response['response']['docs']
        end
        it 'returns correct stats' do
          expect(@stats).to match(
            'View' => { "#{pid}" => 2 },
            'Download' => { "#{pid}" => 1 },
            'Streaming' => { "#{pid}" => 1 },
            'View Lifetime' => { "#{pid}" => 2 },
            'Download Lifetime' => { "#{pid}" => 1 },
            'Streaming Lifetime' => { "#{pid}" => 1 }
          )
        end
        it 'returns correct totals' do
          expect(@totals).to match(
            'View' => 2, 'Download' => 1, 'Streaming' => 1, 'View Lifetime' => 2,
            'Download Lifetime' => 1, 'Streaming Lifetime' => 1
          )
        end
        it 'returns correct download_ids' do
          expect(@download_ids).to include(pid)
          expect(@download_ids[pid]).to contain_exactly('actest:2','actest:4')
        end
      end

      context 'when requesting stats for previous month' do
        before :each do
          @results, @stats, @totals, @download_ids = statistics.instance_eval{
            get_author_stats(Date.today - 2.month, Date.today - 1.month,
              "author_uni:abc123", nil, true, 'author_uni', true, nil)
          }
        end

        it 'returns correct results' do
          expect(@results).to eq solr_response['response']['docs']
        end
        it 'returns empty stats' do
          expect(@stats).to match(
            'View' => {},
            'Download' => { "#{pid}" => 0 },
            'Streaming' => {},
            'View Lifetime' => { "#{pid}" => 2 },
            'Download Lifetime' => { "#{pid}" => 1 },
            'Streaming Lifetime' => { "#{pid}" => 1 }
          )
        end
        it 'returns correct totals' do
          expect(@totals).to match(
            'View' => 0, 'Download' => 0, 'Streaming' => 0, 'View Lifetime' => 2,
            'Download Lifetime' => 1, 'Streaming Lifetime' => 1
          )
        end
      end

      it 'returns correct stats when ommitting streaming views'
    end
  end

  describe '.most_downloaded_asset' do
    let(:pid1) { 'actest:2' }
    let(:pid2) { 'actest:10' }

    subject {
      statistics.instance_eval{ most_downloaded_asset('actest:1') }
    }

    it 'returns error when pid not provided' do
      expect{
        statistics.instance_eval{ most_downloaded_asset }
      }.to raise_error ArgumentError
    end

    context 'when item has one asset' do
      let(:asset_pids_response) do
        [{ pid: pid1 }]
      end

      before :each do
        allow(statistics).to receive(:build_resource_list)
          .with(any_args).and_return(asset_pids_response)
      end

      it 'returns only asset' do
        expect(subject).to eql 'actest:2'
      end
    end

    context 'when item has more than one asset' do
      let(:asset_pids_response) do
        [{ pid: pid1 }, { pid: pid2 }]
      end

      before :each do
        FactoryGirl.create(:download_stat)
        FactoryGirl.create(:download_stat, identifier: pid2)
        FactoryGirl.create(:download_stat, identifier: pid2)
        allow(statistics).to receive(:build_resource_list)
          .with(any_args).and_return(asset_pids_response)
      end

      it 'returns most downloaded' do
        expect(subject).to eql 'actest:10'
      end
    end

    context 'when item asset has never been downloaded' do
      let(:asset_pids_response) do
        [{ pid: pid1 }]
      end

      before :each do
        allow(statistics).to receive(:build_resource_list)
          .with(any_args).and_return(asset_pids_response)
      end

      it 'returns first pid' do
        expect(subject).to eql pid1
      end
    end
  end

  describe '.make_solr_request'

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
        :rows => 100000, :sort => 'title_display asc', :q => nil, :page => 1,
        :fq => "author_uni:\"abc123\"", :fl => "title_display,id,handle,doi,genre_facet"
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
      # FactoryGirl.create_list(:view_stat, 5)
      allow(statistics).to receive(:params).and_return(test_params)
      allow(statistics.repository).to receive(:search)
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
        expect(email.subject).to eql "Academic Commons Monthly Download Report for #{test_params[:month]} #{test_params[:year]} - #{test_params[:month]} #{test_params[:year]}"
      end

      it 'with appropriate title' do
        expect(email.body.to_s).to match /Usage Statistics for abc123/
      end

      it 'with correct view stats' do
        expect(email.body.to_s).to match /5/
      end

      it 'with correct documents' do
        expect(email.body.to_s).to match /First Test Document/
      end
    end
  end

  describe ".get_pids_by_query_facets" do
    context 'when querying by two facets' do
      let(:solr_params) do
        {
          'qt' => 'search', 'rows' => 20000, "facet.field" => ["pid"],
          'fq' => ['{!raw f=Bears}Polar Bears', '{!raw f=Birds}Hummingbird']
        }
      end

      it 'creates correct query' do
        expect(Blacklight.default_index).to receive(:search)
          .with(solr_params).and_return(empty_response)
        statistics.instance_eval{
          get_pids_by_query_facets([['Bears', ['Polar Bears']], ['Birds', ['Hummingbird']]])
        }
      end
    end

    context 'when querying by one facet' do
      let(:solr_params) do
        {
          'qt' => 'search', 'rows' => 20000, "facet.field" => ["pid"],
          'fq' => ['{!raw f=Bears}Polar Bears']
        }
      end

      it 'creates correct query' do
        expect(Blacklight.default_index).to receive(:search)
          .with(solr_params).and_return(empty_response)
        statistics.instance_eval{
          get_pids_by_query_facets([['Bears', ['Polar Bears', 'Black Bear']]])
        }
      end

      it 'ignores query with no facet_item' do
        expect(Blacklight.default_index).to receive(:search)
          .with(solr_params).and_return(empty_response)
        statistics.instance_eval{
          get_pids_by_query_facets([['Bears', ['Polar Bears']], ['Birds', [nil]]])
        }
      end
    end
  end

  describe '.school_pids' do
    let(:solr_params) do
      {
        'qt' => "search", 'rows'=> 20000, 'facet.field'=>["pid"],
        'fq' => ["{!raw f=organization_facet}Carlas Academy"]
      }
    end

    it 'creates correct query' do
      expect(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(empty_response)
      statistics.instance_eval { school_pids('Carlas Academy') }
    end
  end

  describe '.make_months_header' do
    subject { statistics.instance_eval {
      make_months_header("first column", ['Jan', 'Feb', 'Mar', 'Apr'])
    }}

    it 'makes header array' do
      expect(subject).to eq ['first column', '', '', '']
    end
  end
end
