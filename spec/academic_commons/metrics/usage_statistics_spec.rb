require 'rails_helper'

RSpec.describe AcademicCommons::Metrics::UsageStatistics, integration: true do
  let(:uni) { 'abc123' }
  let(:pid) { 'actest:1' }
  let(:pid2) { 'actest:5' }
  let(:empty_response) { { 'response' => { 'docs' => [] } } }
  let(:usage_stats) { AcademicCommons::Metrics::UsageStatistics.new({}, nil, nil) }
  let(:solr_request) { { q: nil, fq: ["author_uni:\"#{uni}\""] } }
  let(:solr_params) do
    {
      rows: 100_000, sort: 'title_display asc', q: nil, page: 1,
      fq: ["author_uni:\"#{uni}\"", 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
      fl: 'title_display,id,handle,doi,genre_facet,record_creation_date,object_state_ssi,free_to_read_start_date'
    }
  end
  let(:solr_response) do
    Blacklight::Solr::Response.new(
      {
        'response' => {
          'docs' => [
            { 'id' => pid2, 'title_display' => 'Second Test Document', 'object_state_ssi' => 'A',
             'handle' => 'http://dx.doi.org/10.7916/TESTDOC2', 'doi' => '', 'genre_facet' => ''},
            { 'id' => pid, 'title_display' => 'First Test Document', 'object_state_ssi' => 'A',
              'handle' => 'http://dx.doi.org/10.7916/TESTDOC1', 'doi' => '', 'genre_facet' => '' }
          ]
        }
      }, {}
    )
  end

  describe '.new' do
    context 'when requesting usage stats for author' do
      before :each do
        # Add records for a pid view and download
        FactoryBot.create(:view_stat)
        FactoryBot.create(:view_stat)
        FactoryBot.create(:download_stat)
        FactoryBot.create(:streaming_stat)

        allow(Blacklight.default_index).to receive(:search)
          .with(solr_params).and_return(solr_response)
      end

      context 'when requesting stats for an author with embargoed material' do
        let(:solr_response) do
          Blacklight::Solr::Response.new(
            {
              'response' => {
                'docs' => [
                  { 'id' => pid2, 'title_display' => 'Second Test Document', 'object_state_ssi' => 'A',
                   'handle' => 'http://dx.doi.org/10.7916/TESTDOC2', 'doi' => '', 'genre_facet' => ''},
                  { 'id' => pid, 'title_display' => 'First Test Document', 'object_state_ssi' => 'A',
                    'handle' => 'http://dx.doi.org/10.7916/TESTDOC1', 'doi' => '', 'genre_facet' => '' },
                  { 'id' => 'actest:10', 'title_display' => 'First Test Document', 'object_state_ssi' => 'A',
                    'handle' => 'http://dx.doi.org/10.7916/TESTDOC1', 'doi' => '', 'genre_facet' => '',
                    'free_to_read_start_date' => Date.tomorrow.strftime('%Y-%m-%d') }
                ]
              }
            }, {}
          )
        end

        subject do
          AcademicCommons::Metrics::UsageStatistics.new(solr_request)
        end

        it 'removes embargoed material' do
          expect(subject.count).to eq 2
          expect(subject.find{ |i| i.id == 'actest:10' }).to eq nil
        end

        it 'calculates stats for available material' do
          expect(subject.total_for(Statistic::VIEW, 'Lifetime')).to eq 2
          expect(subject.total_for(Statistic::DOWNLOAD, 'Lifetime')).to eq 1
        end
      end

      context 'when request lifetime stats' do
        before :each do
          FactoryBot.create(:view_stat, at_time: Date.new(2001, 4, 12))
        end

        subject do
          AcademicCommons::Metrics::UsageStatistics.new(solr_request, include_streaming: true)
        end

        it 'returns correct results' do
          expect(subject.map(&:document)).to eq solr_response['response']['docs']
        end

        it 'returns correct totals for lifetime' do
          expect(subject.total_for(Statistic::VIEW, 'Lifetime')).to be 3
          expect(subject.total_for(Statistic::DOWNLOAD, 'Lifetime')).to be 1
          expect(subject.total_for(Statistic::STREAM, 'Lifetime')).to be 1
        end

        it 'returns error if period stats are requested' do
          expect{
            subject.total_for(Statistic::VIEW, 'Period')
          }.to raise_error 'View Period not part of stats. Check parameters.'
        end
      end

      context 'when requesting stats for current month' do
        subject do
          AcademicCommons::Metrics::UsageStatistics.new(solr_request, Date.current - 1.month, Date.current,
          include_zeroes: true, include_streaming: true)
        end

        it 'returns correct results' do
          expect(subject.map(&:document)).to eq solr_response['response']['docs']
        end
        it 'returns correct totals' do
          expect(subject.total_for(Statistic::VIEW, 'Period')).to be 2
          expect(subject.total_for(Statistic::DOWNLOAD, 'Period')).to be 1
          expect(subject.total_for(Statistic::STREAM, 'Period')).to be 1
          expect(subject.total_for(Statistic::VIEW, 'Lifetime')).to be 2
          expect(subject.total_for(Statistic::DOWNLOAD, 'Lifetime')).to be 1
          expect(subject.total_for(Statistic::STREAM, 'Lifetime')).to be 1
        end
      end

      context 'when requesting stats for previous month' do
        subject do
          AcademicCommons::Metrics::UsageStatistics.new(solr_request, Date.current - 2.month, Date.current - 1.month,
          include_zeroes: true, include_streaming: true)
        end

        it 'returns correct results' do
          expect(subject.map(&:document)).to eq solr_response['response']['docs']
        end

        it 'returns correct totals' do
          expect(subject.total_for(Statistic::VIEW, 'Period')).to be 0
          expect(subject.total_for(Statistic::DOWNLOAD, 'Period')).to be 0
          expect(subject.total_for(Statistic::STREAM, 'Period')).to be 0
          expect(subject.total_for(Statistic::VIEW, 'Lifetime')).to be 2
          expect(subject.total_for(Statistic::DOWNLOAD, 'Lifetime')).to be 1
          expect(subject.total_for(Statistic::STREAM, 'Lifetime')).to be 1
        end
      end

      context 'when requesting stats without streaming' do
        subject do
          AcademicCommons::Metrics::UsageStatistics.new(solr_request, Date.current - 1.month, Date.current,
          include_zeroes: true)
        end

        it 'returns correct totals' do
          expect(subject.total_for(Statistic::VIEW, 'Period')).to be 2
          expect(subject.total_for(Statistic::DOWNLOAD, 'Period')).to be 1
          expect(subject.total_for(Statistic::VIEW, 'Lifetime')).to be 2
          expect(subject.total_for(Statistic::DOWNLOAD, 'Lifetime')).to be 1
        end
      end

      context 'when requesting stats without zeroes' do
        subject do
          AcademicCommons::Metrics::UsageStatistics.new(solr_request, Date.current - 2.month, Date.current - 1.month,
          include_zeroes: false, include_streaming: true)
        end

        it 'results does not include records with zero for view and download stats' do
          expect(subject.map(&:id)).not_to include 'actest:5'
        end
      end
    end
  end

  describe '#make_months_list' do
    let(:dates) do
      ['Dec-2015', 'Jan-2016', 'Feb-2016', 'Mar-2016', 'Apr-2016'].map { |d| Date.parse(d) }
    end
    let(:usage_stats) { AcademicCommons::Metrics::UsageStatistics.new({}, dates.first, dates.last) }

    it 'returns correct list' do
      result = usage_stats.instance_eval { make_months_list }
      expect(result).to eq dates
    end
    it 'returns correct list in reverse' do
      result = usage_stats.instance_eval{ make_months_list(true) }
      expect(result).to eq dates.reverse
    end
  end

  describe '#to_csv_by_month' do
    let(:pid) { 'actest:1' }
    let(:uni) { 'abc123' }
    let(:expected_csv) do
      [
        ['{:q=>nil, :fq=>["author_uni:\\"abc123\\""]}'],
        [],
        ['Period Covered by Report', 'Jan 2015 - Dec 2016'],
        [],
        ['Report created by:', 'N/A'],
        ['Report created on:', Time.new.strftime('%Y-%m-%d')],
        [], [],
        ['VIEWS REPORT:'],
        ['Total for period:', '2', '', '', '', 'Views by Month'],
        ['Title', 'Content Type', 'Persistent URL', 'Publisher DOI', 'Reporting Period Total Views', 'Jan-2015', 'Feb-2015', 'Mar-2015', 'Apr-2015', 'May-2015', 'Jun-2015', 'Jul-2015', 'Aug-2015', 'Sep-2015', 'Oct-2015', 'Nov-2015', 'Dec-2015', 'Jan-2016', 'Feb-2016', 'Mar-2016', 'Apr-2016', 'May-2016', 'Jun-2016', 'Jul-2016', 'Aug-2016', 'Sep-2016', 'Oct-2016', 'Nov-2016', 'Dec-2016'],
        ['First Test Document', '', 'http://dx.doi.org/10.7916/TESTDOC1', '', '2', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Second Test Document', '', 'http://dx.doi.org/10.7916/TESTDOC2', '', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'],

        [], [],
        ['STREAMS REPORT:'],
        ['Total for period:', '1', '', '', '', 'Streams by Month'],
        ['Title', 'Content Type', 'Persistent URL', 'Publisher DOI', 'Reporting Period Total Streams', 'Jan-2015', 'Feb-2015', 'Mar-2015', 'Apr-2015', 'May-2015', 'Jun-2015', 'Jul-2015', 'Aug-2015', 'Sep-2015', 'Oct-2015', 'Nov-2015', 'Dec-2015', 'Jan-2016', 'Feb-2016', 'Mar-2016', 'Apr-2016', 'May-2016', 'Jun-2016', 'Jul-2016', 'Aug-2016', 'Sep-2016', 'Oct-2016', 'Nov-2016', 'Dec-2016'],
        ['First Test Document', '', 'http://dx.doi.org/10.7916/TESTDOC1', '', '1', '0', '0', '0', '0', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Second Test Document', '', 'http://dx.doi.org/10.7916/TESTDOC2', '', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'],

        [], [],
        ['DOWNLOADS REPORT:'],
        ['Total for period:', '2', '', '', '', 'Downloads by Month'],
        ['Title', 'Content Type', 'Persistent URL', 'Publisher DOI', 'Reporting Period Total Downloads', 'Jan-2015', 'Feb-2015', 'Mar-2015', 'Apr-2015', 'May-2015', 'Jun-2015', 'Jul-2015', 'Aug-2015', 'Sep-2015', 'Oct-2015', 'Nov-2015', 'Dec-2015', 'Jan-2016', 'Feb-2016', 'Mar-2016', 'Apr-2016', 'May-2016', 'Jun-2016', 'Jul-2016', 'Aug-2016', 'Sep-2016', 'Oct-2016', 'Nov-2016', 'Dec-2016'],
        ['First Test Document', '', 'http://dx.doi.org/10.7916/TESTDOC1', '', '2', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '2', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Second Test Document', '', 'http://dx.doi.org/10.7916/TESTDOC2', '', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0']
      ]
    end
    let(:usage_stats) do
      AcademicCommons::Metrics::UsageStatistics.new(solr_request, Date.parse('Jan 2015'), Date.parse('Dec 2016'),
      order_by: 'views', include_zeroes: true, include_streaming: true, per_month: true)
    end

    before :each do
      FactoryBot.create(:view_stat, at_time: Date.parse('Jan 15, 2015'))
      FactoryBot.create(:view_stat, at_time: Date.parse('March 9, 2016'))
      FactoryBot.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryBot.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryBot.create(:streaming_stat, at_time: Date.parse('May 3, 2015'))

      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'creates the expected csv' do
      csv = usage_stats.to_csv_by_month
      expect(CSV.parse(csv)).to match expected_csv
    end
  end

  describe '#get_stat_for' do
    subject do
      AcademicCommons::Metrics::UsageStatistics.new(solr_request, Date.parse('Dec 2015'), Date.parse('Apr 2016'),
      per_month: true)
    end

    before :each do
      FactoryBot.create(:view_stat, at_time: Date.parse('Jan 15, 2016'))
      FactoryBot.create(:view_stat, at_time: Date.parse('March 9, 2016'))
      FactoryBot.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryBot.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryBot.create(:streaming_stat, at_time: Date.parse('May 3, 2015'))

      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'return correct value for view period stats' do
      expect(subject.get_stat_for(pid, Statistic::VIEW)).to be 2
    end

    it 'returns correct value for view month stats' do
      expect(subject.get_stat_for(pid, Statistic::VIEW, 'Jan 2016')).to be 1
    end

    it 'returns correct value of Lifetime download stats' do
      expect(subject.get_stat_for(pid, Statistic::DOWNLOAD, 'Lifetime')).to be 2
    end

    it 'returns correct value of download April 2016 stats' do
      expect(subject.get_stat_for(pid, Statistic::DOWNLOAD, 'Apr 2016')).to be 2
    end

    it 'returns error if month and year are not part of the period' do
      expect {
        subject.get_stat_for(pid, Statistic::VIEW, 'May 2017')
      }.to raise_error 'View May 2017 not part of stats. Check parameters.'
    end

    it 'returns error if id not part of results' do
      expect {
        subject.get_stat_for('actest:134', Statistic::VIEW, 'Jan 2016')
      }.to raise_error 'Could not find actest:134'
    end

    it 'returns 0 if id not present, but id part of results' do
      expect(subject.get_stat_for('actest:5', Statistic::VIEW, 'Jan 2016')).to be 0
    end
  end

  describe '#most_downloaded_asset' do
    let(:pid1) { 'actest:2' }
    let(:pid2) { 'actest:4' }

    subject {
      usage_stats.instance_eval{
        most_downloaded_asset(
          { 'id' => 'actest:1', 'title_display' => 'Second Test Document', 'object_state_ssi' => 'A',
            'handle' => 'http://dx.doi.org/10.7916/TESTDOC2', 'doi' => '', 'genre_facet' => '' }
        )
      }
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
        FactoryBot.create(:download_stat)
        FactoryBot.create(:download_stat, identifier: pid2)
        FactoryBot.create(:download_stat, identifier: pid2)
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

  describe '.time_period' do
    subject{ usage_stats.instance_eval{ time_period } }

    context 'when start and end date available' do
      let(:usage_stats) { AcademicCommons::Metrics::UsageStatistics.new(solr_params, Date.parse('Jan 2015'), Date.parse('Dec 2016')) }
      it { is_expected.to eq 'Jan 2015 - Dec 2016' }
    end

    context 'when start and end date not available' do
      let(:usage_stats) { AcademicCommons::Metrics::UsageStatistics.new(solr_params) }
      it { is_expected.to eq 'Lifetime' }
    end

    context 'when stats are for one month' do
      let(:date) { Date.current }
      let(:usage_stats) { AcademicCommons::Metrics::UsageStatistics.new(solr_params, date, date) }
      it { is_expected.to eq date.strftime('%b %Y') }
    end
  end
end
