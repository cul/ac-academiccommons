require 'rails_helper'

RSpec.describe AcademicCommons::UsageStatistics, integration: true do
  let(:uni) { 'abc123' }
  let(:pid) { 'actest:1' }
  let(:pid2) { 'actest:5' }
  let(:empty_response) { { 'response' => { 'docs' => [] } } }
  let(:usage_stats) { AcademicCommons::UsageStatistics.new('', '', '', '') }
  let(:solr_params) do
    {
      :rows => 100000, :sort => 'title_display asc', :q => nil, :page => 1,
      :fq => "author_uni:\"author_uni:#{uni}\"", :fl => "title_display,id,handle,doi,genre_facet"
    }
  end
  let(:solr_response) do
    {
      'response' => {
        'docs' => [
          { 'id' => pid2, 'title_display' => 'Second Test Document',
           'handle' => 'http://dx.doi.org/10.7916/TESTDOC2', 'doi' => '', 'genre_facet' => ''},
          { 'id' => pid, 'title_display' => 'First Test Document',
            'handle' => 'http://dx.doi.org/10.7916/TESTDOC1', 'doi' => '', 'genre_facet' => '' }
          ]
        }
      }
  end

  describe '.new' do
    context 'when requesting usage stats for author' do
      let(:results) { usage_stats.results }
      let(:stats)   { usage_stats.stats }
      let(:totals)  { usage_stats.totals }
      let(:download_ids) { usage_stats.download_ids}

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
        let(:usage_stats) do
          AcademicCommons::UsageStatistics.new(Date.today - 1.month, Date.today,
          "author_uni:abc123", 'author_uni', include_zeroes: true, include_streaming: true)
        end

        it 'returns correct results' do
          expect(results).to eq solr_response['response']['docs']
        end
        it 'returns correct stats' do
          expect(stats).to match(
            'View Period' => { "#{pid}" => 2 },
            'Download Period' => { "#{pid}" => 1 },
            'Streaming Period' => { "#{pid}" => 1 },
            'View Lifetime' => { "#{pid}" => 2 },
            'Download Lifetime' => { "#{pid}" => 1 },
            'Streaming Lifetime' => { "#{pid}" => 1 }
          )
        end
        it 'returns correct totals' do
          expect(totals).to match(
            'View Period' => 2, 'Download Period' => 1, 'Streaming Period' => 1, 'View Lifetime' => 2,
            'Download Lifetime' => 1, 'Streaming Lifetime' => 1
          )
        end
        it 'returns correct download_ids' do
          expect(download_ids).to include(pid)
          expect(download_ids[pid]).to eql 'actest:2'
        end
      end

      context 'when requesting stats for previous month' do
        let(:usage_stats) do
          AcademicCommons::UsageStatistics.new(Date.today - 2.month, Date.today - 1.month,
          "author_uni:abc123", 'author_uni', include_zeroes: true, include_streaming: true)
        end

        it 'returns correct results' do
          expect(results).to eq solr_response['response']['docs']
        end

        it 'returns empty stats' do
          expect(stats).to match(
            'View Period' => {},
            'Download Period' => {},
            'Streaming Period' => {},
            'View Lifetime' => { "#{pid}" => 2 },
            'Download Lifetime' => { "#{pid}" => 1 },
            'Streaming Lifetime' => { "#{pid}" => 1 }
          )
        end
        it 'returns correct totals' do
          expect(totals).to match(
            'View Period' => 0, 'Download Period' => 0, 'Streaming Period' => 0, 'View Lifetime' => 2,
            'Download Lifetime' => 1, 'Streaming Lifetime' => 1
          )
        end
      end

      context 'when requesting stats without streaming' do
        let(:usage_stats) do
          AcademicCommons::UsageStatistics.new(Date.today - 1.month, Date.today,
          "author_uni:abc123", 'author_uni', include_zeroes: true)
        end

        it 'returns correct stats' do
          expect(stats).to match(
            'View Period' => { "#{pid}" => 2 },
            'Download Period' => { "#{pid}" => 1 },
            'View Lifetime' => { "#{pid}" => 2 },
            'Download Lifetime' => { "#{pid}" => 1 },
          )
        end
      end

      context 'when requesting stats without zeroes' do
        let(:usage_stats) do
          AcademicCommons::UsageStatistics.new(Date.today - 2.month, Date.today - 1.month,
          "author_uni:abc123", 'author_uni', include_zeroes: true, include_streaming: true)
        end

        it 'results does not include records with zero for view and download stats' do
          ids = results.map { |r| r['id'] }
          expect(results).not_to include 'actest:5'
        end
      end
    end
  end

  describe '#make_months_list' do
    let(:dates) do
      ['Dec-2015', 'Jan-2016', 'Feb-2016', 'Mar-2016', 'Apr-2016'].map { |d| Date.parse(d) }
    end
    let(:usage_stats) { AcademicCommons::UsageStatistics.new(dates.first, dates.last, '', '') }

    it 'returns correct list' do
      result = usage_stats.instance_eval { make_months_list }
      expect(result).to eq dates
    end
    it 'returns correct list in reverse' do
      result = usage_stats.instance_eval{ make_months_list(true) }
      expect(result).to eq dates.reverse
    end
  end

  describe '#make_solr_request' do
    context 'searching by facet' do
      let(:solr_params) do
        {
          :rows => 100000, :sort => "title_display asc", :q => nil, :fq => 'author_uni:"xyz123"',
          :fl => "title_display,id,handle,doi,genre_facet", :page => 1
        }
      end

      it 'makes correct solr request' do
        expect(Blacklight.default_index).to receive(:search).with(solr_params).and_return(empty_response)
        usage_stats.instance_eval { make_solr_request('author_uni', 'xyz123') }
      end
    end

    context 'searching by query' do
      let(:test_params) { { 'f' => 'department_facet:Columbia College', 'q' => '', 'sort' => 'author_sort asc'} }
      let(:solr_params) do
        {
          :rows => 100000, :sort => 'author_sort asc', :q => '', :fq => 'department_facet:Columbia College',
          :fl => "title_display,id,handle,doi,genre_facet", :page => 1
        }
      end

      before :each do
        allow(usage_stats).to receive(:parse_search_query).and_return(test_params)
      end

      it 'makes correct solr request' do
        expect(Blacklight.default_index).to receive(:search).with(solr_params).and_return(empty_response)
        usage_stats.instance_eval { make_solr_request('search_query', 'author_uni=xyz123') }
      end
    end
  end

  describe '#to_csv_by_month' do
    let(:pid) { 'actest:1' }
    let(:uni) { 'abc123' }
    let(:expected_csv) do
      [
        ["Author UNI/Name:", "author_uni:abc123"],
        [],
        ["Period Covered by Report", "Jan 2015 to Dec 2016"],
        [],
        ["Report created by:", "N/A"],
        ["Report created on:", Time.new.strftime("%Y-%m-%d")],
        [], [],
        ["VIEWS REPORT:"],
        ["Total for period:", "2", "", "", "", "Views by Month"],
        ["Title", "Content Type", "Persistent URL", "Publisher DOI", "Reporting Period Total Views", "Jan-2015", "Feb-2015", "Mar-2015", "Apr-2015", "May-2015", "Jun-2015", "Jul-2015", "Aug-2015", "Sep-2015", "Oct-2015", "Nov-2015", "Dec-2015", "Jan-2016", "Feb-2016", "Mar-2016", "Apr-2016", "May-2016", "Jun-2016", "Jul-2016", "Aug-2016", "Sep-2016", "Oct-2016", "Nov-2016", "Dec-2016"],
        ["First Test Document", "", "http://dx.doi.org/10.7916/TESTDOC1", "", "2", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0"],
        ["Second Test Document", "", "http://dx.doi.org/10.7916/TESTDOC2", "", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"],

        [], [],
        ["STREAMS REPORT:"],
        ["Total for period:", "1", "", "", "", "Streams by Month"],
        ["Title", "Content Type", "Persistent URL", "Publisher DOI", "Reporting Period Total Streams", "Jan-2015", "Feb-2015", "Mar-2015", "Apr-2015", "May-2015", "Jun-2015", "Jul-2015", "Aug-2015", "Sep-2015", "Oct-2015", "Nov-2015", "Dec-2015", "Jan-2016", "Feb-2016", "Mar-2016", "Apr-2016", "May-2016", "Jun-2016", "Jul-2016", "Aug-2016", "Sep-2016", "Oct-2016", "Nov-2016", "Dec-2016"],
        ["First Test Document", "", "http://dx.doi.org/10.7916/TESTDOC1", "", "1", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"],
        ["Second Test Document", "", "http://dx.doi.org/10.7916/TESTDOC2", "", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"],

        [], [],
        ["DOWNLOADS REPORT:"],
        ["Total for period:", "2", "", "", "", "Downloads by Month"],
        ["Title", "Content Type", "Persistent URL", "Publisher DOI", "Reporting Period Total Downloads", "Jan-2015", "Feb-2015", "Mar-2015", "Apr-2015", "May-2015", "Jun-2015", "Jul-2015", "Aug-2015", "Sep-2015", "Oct-2015", "Nov-2015", "Dec-2015", "Jan-2016", "Feb-2016", "Mar-2016", "Apr-2016", "May-2016", "Jun-2016", "Jul-2016", "Aug-2016", "Sep-2016", "Oct-2016", "Nov-2016", "Dec-2016"],
        ["First Test Document", "", "http://dx.doi.org/10.7916/TESTDOC1", "", "2", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "2", "0", "0", "0", "0", "0", "0", "0", "0"],
        ["Second Test Document", "", "http://dx.doi.org/10.7916/TESTDOC2", "", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0"]
      ]
    end
    let(:usage_stats) do
      AcademicCommons::UsageStatistics.new(Date.parse('Jan 2015'), Date.parse('Dec 2016'),
      "author_uni:abc123", 'author_uni', order_by: 'views', include_zeroes: true, include_streaming: true, per_month: true)
    end

    before :each do
      FactoryGirl.create(:view_stat, at_time: Date.parse('Jan 15, 2015'))
      FactoryGirl.create(:view_stat, at_time: Date.parse('March 9, 2016'))
      FactoryGirl.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryGirl.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryGirl.create(:streaming_stat, at_time: Date.parse('May 3, 2015'))

      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'creates the expected csv' do
      csv = usage_stats.to_csv_by_month
      expect(CSV.parse(csv)).to match expected_csv
    end
  end

  describe '#get_stat_for' do
    let(:usage_stats) do
      AcademicCommons::UsageStatistics.new(Date.parse('Dec 2015'), Date.parse('Apr 2016'),
      "author_uni:abc123", 'author_uni', per_month: true)
    end

    before :each do
      FactoryGirl.create(:view_stat, at_time: Date.parse('Jan 15, 2016'))
      FactoryGirl.create(:view_stat, at_time: Date.parse('March 9, 2016'))
      FactoryGirl.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryGirl.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryGirl.create(:streaming_stat, at_time: Date.parse('May 3, 2015'))

      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'return correct value for view period stats' do
      expect(usage_stats.get_stat_for(pid, 'View')).to eql 2
    end

    it 'returns correct value for view month stats' do
      expect(usage_stats.get_stat_for(pid, 'View', 'Jan 2016')).to eql 1
    end

    it 'returns correct value of Lifetime download stats' do
      expect(usage_stats.get_stat_for(pid, 'Download', 'Lifetime')).to eql 2
    end

    it 'returns correct value of download April 2016 stats' do
      expect(usage_stats.get_stat_for(pid, 'Download', 'Apr 2016')).to eql 2
    end

    it 'returns error if month and year are not part of the period' do
      expect {
        usage_stats.get_stat_for(pid, 'View', 'May 2017')
      }.to raise_error 'View May 2017 not part of stats. Check parameters.'
    end

    it 'returns error if id not part of results' do
      expect {
        usage_stats.get_stat_for('actest:134', 'View', 'Jan 2016')
      }.to raise_error 'id given not part of results'
    end

    it 'returns 0 if id not present, but id part of results' do
      expect(usage_stats.get_stat_for('actest:5', 'View', "Jan 2016")).to eql 0
    end
  end

  describe '#most_downloaded_asset' do
    let(:pid1) { 'actest:2' }
    let(:pid2) { 'actest:4' }

    subject {
      usage_stats.instance_eval{ most_downloaded_asset('actest:1') }
    }

    it 'returns error when pid not provided' do
      expect {
        usage_stats.instance_eval{ most_downloaded_asset }
      }.to raise_error ArgumentError
    end

    context 'when item has one asset' do
      let(:asset_pids_response) { [{ pid: pid1 }] }

      before :each do
        allow(usage_stats).to receive(:build_resource_list)
          .with(any_args).and_return(asset_pids_response)
      end

      it 'returns only asset' do
        expect(subject).to eql 'actest:2'
      end
    end

    context 'when item has more than one asset' do
      before :each do
        FactoryGirl.create(:download_stat)
        FactoryGirl.create(:download_stat, identifier: pid2)
        FactoryGirl.create(:download_stat, identifier: pid2)
      end

      it 'returns most downloaded' do
        expect(subject).to eql pid2
      end
    end

    context 'when item asset has never been downloaded' do
      it 'returns first pid' do
        expect(subject).to eql pid1
      end
    end
  end
end
