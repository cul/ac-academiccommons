require 'rails_helper'

RSpec.describe AcademicCommons::Metrics::UsageStatistics, integration: true do
  let(:uni) { 'abc123' }
  let(:doi) { '10.7916/ALICE' }
  let(:doi5) { '10.7916/TESTDOC5' }
  let(:empty_response) { { 'response' => { 'docs' => [] } } }
  let(:usage_stats) { AcademicCommons::Metrics::UsageStatistics.new({}, nil, nil) }
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
            { 'id' => doi5, 'title_ssi' => 'Second Test Document', 'object_state_ssi' => 'A', 'record_creation_dtsi' => '2018-08-07T03:40:22Z',
              'cul_doi_ssi' => doi5, 'fedora3_pid_ssi' => 'actest:5', 'publisher_doi_ssi' => '', 'genre_ssim' => '' },
            { 'id' => doi, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A', 'record_creation_dtsi' => '2018-08-07T03:40:22Z',
              'cul_doi_ssi' => doi, 'fedora3_pid_ssi' => 'actest:1', 'publisher_doi_ssi' => '', 'genre_ssim' => '' }
          ]
        }
      }, {}
    )
  end

  describe '.new' do
    context 'when requesting usage stats for author' do
      before do
        # Add records for a pid view and download
        FactoryBot.create(:view_stat)
        FactoryBot.create(:view_stat)
        FactoryBot.create(:download_stat)
        FactoryBot.create(:streaming_stat)

        allow(Blacklight.default_index).to receive(:search)
          .with(solr_params).and_return(solr_response)
      end

      context 'when requesting stats for an author with embargoed material' do
        subject(:usage_stats) { AcademicCommons::Metrics::UsageStatistics.new(solr_request) }

        let(:solr_response) do
          Blacklight::Solr::Response.new(
            {
              'response' => {
                'docs' => [
                  { 'id' => '10.7916/TESTDOC2', 'fedora3_pid_ssi' => 'actest:2', 'title_ssi' => 'Second Test Document', 'object_state_ssi' => 'A',
                    'cul_doi_ssi' => '10.7916/TESTDOC2', 'genre_ssim' => '', 'publisher_doi_ssi' => '' },
                  { 'id' => doi, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                    'cul_doi_ssi' => doi, 'fedora3_pid_ssi' => 'actest:1', 'genre_ssim' => '', 'publisher_doi_ssi' => '' },
                  { 'id' => '10.7916/TESTDOC10', 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                    'cul_doi_ssi' => '10.7916/TESTDOC10', 'fedora3_pid_ssi' => 'actest:10', 'genre_ssim' => '', 'publisher_doi_ssi' => '',
                    'free_to_read_start_date_ssi' => Date.current.tomorrow.strftime('%Y-%m-%d') }
                ]
              }
            }, {}
          )
        end

        it 'removes embargoed material' do
          expect(usage_stats.count).to eq 2
          expect(usage_stats.find { |i| i.id == '10.7916/TESTDOC10' }).to eq nil
        end

        it 'calculates stats for available material' do
          expect(usage_stats.total_for(Statistic::VIEW, 'Lifetime')).to eq 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, 'Lifetime')).to eq 1
        end
      end

      context 'when request lifetime stats' do
        before do
          FactoryBot.create(:view_stat, at_time: Date.new(2001, 4, 12))
        end

        subject(:usage_stats) do
          AcademicCommons::Metrics::UsageStatistics.new(solr_request, include_streaming: true)
        end

        it 'returns correct results' do
          expect(usage_stats.map(&:document)).to eq solr_response.documents
        end

        it 'returns correct totals for lifetime' do
          expect(usage_stats.total_for(Statistic::VIEW, 'Lifetime')).to be 3
          expect(usage_stats.total_for(Statistic::DOWNLOAD, 'Lifetime')).to be 1
          expect(usage_stats.total_for(Statistic::STREAM, 'Lifetime')).to be 1
        end

        it 'returns error if period stats are requested' do
          expect {
            usage_stats.total_for(Statistic::VIEW, 'Period')
          }.to raise_error 'View Period not part of stats. Check parameters.'
        end
      end

      context 'when requesting stats for current month' do
        subject(:usage_stats) do
          AcademicCommons::Metrics::UsageStatistics.new(
            solr_request, Date.current - 1.month, Date.current,
            include_zeroes: true, include_streaming: true
          )
        end

        it 'returns correct results' do
          expect(subject.map(&:document)).to eq solr_response.documents
        end

        it 'returns correct totals' do
          expect(usage_stats.total_for(Statistic::VIEW, 'Period')).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, 'Period')).to be 1
          expect(usage_stats.total_for(Statistic::STREAM, 'Period')).to be 1
          expect(usage_stats.total_for(Statistic::VIEW, 'Lifetime')).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, 'Lifetime')).to be 1
          expect(usage_stats.total_for(Statistic::STREAM, 'Lifetime')).to be 1
        end
      end

      context 'when requesting stats for previous month' do
        subject(:usage_stats) do
          AcademicCommons::Metrics::UsageStatistics.new(
            solr_request, Date.current - 2.months, Date.current - 1.month,
            include_zeroes: true, include_streaming: true
          )
        end

        it 'returns correct results' do
          expect(usage_stats.map(&:document)).to eq solr_response.documents
        end

        it 'returns correct totals' do
          expect(usage_stats.total_for(Statistic::VIEW, 'Period')).to be 0
          expect(usage_stats.total_for(Statistic::DOWNLOAD, 'Period')).to be 0
          expect(usage_stats.total_for(Statistic::STREAM, 'Period')).to be 0
          expect(usage_stats.total_for(Statistic::VIEW, 'Lifetime')).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, 'Lifetime')).to be 1
          expect(usage_stats.total_for(Statistic::STREAM, 'Lifetime')).to be 1
        end
      end

      context 'when requesting stats without streaming' do
        subject(:usage_stats) do
          AcademicCommons::Metrics::UsageStatistics.new(
            solr_request, Date.current - 1.month, Date.current, include_zeroes: true
          )
        end

        it 'returns correct totals' do
          expect(usage_stats.total_for(Statistic::VIEW, 'Period')).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, 'Period')).to be 1
          expect(usage_stats.total_for(Statistic::VIEW, 'Lifetime')).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, 'Lifetime')).to be 1
        end
      end

      context 'when requesting stats without zeroes' do
        subject(:usage_stats) do
          AcademicCommons::Metrics::UsageStatistics.new(
            solr_request, Date.current - 2.months, Date.current - 1.month,
            include_zeroes: false, include_streaming: true
          )
        end

        it 'results does not include records with zero for view and download stats' do
          expect(usage_stats.map(&:id)).not_to include 'actest:5'
        end
      end
    end
  end

  describe '#months_list' do
    let(:dates) do
      ['Dec 2015', 'Jan 2016', 'Feb 2016', 'Mar 2016', 'Apr 2016'].map { |d| Date.parse(d) }
    end

    it 'returns correct list' do
      usage_stats = AcademicCommons::Metrics::UsageStatistics.new({}, dates.first, dates.last)
      result = usage_stats.instance_eval { months_list }
      expect(result).to eq dates
    end

    it 'returns correct list in reverse' do
      usage_stats = AcademicCommons::Metrics::UsageStatistics.new({}, dates.first, dates.last, recent_first: true)
      result = usage_stats.instance_eval { months_list }
      expect(result).to eq dates.reverse
    end
  end

  describe '#time_period_csv' do
    let(:uni) { 'abc123' }
    let(:expected_csv) do
      [
        ['Period Covered by Report:', 'Jan 2015 - Dec 2016'],
        ['Raw Query:', '{:q=>nil, :fq=>["author_uni_ssim:\\"abc123\\""]}'],
        ['Order:', 'Views'],
        ['Report created by:', 'N/A'],
        ['Report created on:', Time.current.strftime('%Y-%m-%d')],
        ['Total number of items:', '2'],
        [],
        ['Title', 'Genre', 'DOI', 'Record Creation Date', 'Views', 'Downloads'],
        ['First Test Document', '', '10.7916/ALICE', '08/07/2018', '2', '2'],
        ['Second Test Document', '', '10.7916/TESTDOC5', '08/07/2018', '0', '0'],
        [nil, nil, nil, 'Totals:', '2', '2']
      ]
    end
    let(:usage_stats) do
      AcademicCommons::Metrics::UsageStatistics.new(
        solr_request, Time.zone.parse('Jan 2015'), Time.zone.parse('Dec 2016'),
        order_by: 'views', include_zeroes: true
      )
    end

    before do
      FactoryBot.create(:view_stat, at_time: Time.zone.parse('Jan 15, 2015'))
      FactoryBot.create(:view_stat, at_time: Time.zone.parse('March 9, 2016'))
      FactoryBot.create(:download_stat, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:download_stat, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:streaming_stat, at_time: Time.zone.parse('May 3, 2015'))
      FactoryBot.create(:view_stat, at_time: Time.zone.parse('Jan 7, 2017'))

      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'creates the expected csv' do
      csv = usage_stats.time_period_csv
      expect(CSV.parse(csv)).to match expected_csv
    end
  end

  describe '#month_by_month_csv' do
    let(:expected_csv) do
      [
        ['Period Covered by Report:', 'Jan 2015 - Dec 2016'],
        ['Raw Query:', '{:q=>nil, :fq=>["author_uni_ssim:\\"abc123\\""]}'],
        ['Order:', 'Views'],
        ['Report created by:', 'N/A'],
        ['Report created on:', Time.current.strftime('%Y-%m-%d')],
        ['Total number of items:', '2'],
        [],
        ['VIEWS'],
        ['Title', 'Genre', 'DOI', 'Record Creation Date', 'Jan 2015', 'Feb 2015', 'Mar 2015', 'Apr 2015', 'May 2015', 'Jun 2015', 'Jul 2015', 'Aug 2015', 'Sep 2015', 'Oct 2015', 'Nov 2015', 'Dec 2015', 'Jan 2016', 'Feb 2016', 'Mar 2016', 'Apr 2016', 'May 2016', 'Jun 2016', 'Jul 2016', 'Aug 2016', 'Sep 2016', 'Oct 2016', 'Nov 2016', 'Dec 2016'],
        ['First Test Document', '', '10.7916/ALICE', '08/07/2018', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Second Test Document', '', '10.7916/TESTDOC5', '08/07/2018', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        [nil, nil, nil, 'Totals:', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        [],
        ['DOWNLOADS'],
        ['Title', 'Genre', 'DOI', 'Record Creation Date', 'Jan 2015', 'Feb 2015', 'Mar 2015', 'Apr 2015', 'May 2015', 'Jun 2015', 'Jul 2015', 'Aug 2015', 'Sep 2015', 'Oct 2015', 'Nov 2015', 'Dec 2015', 'Jan 2016', 'Feb 2016', 'Mar 2016', 'Apr 2016', 'May 2016', 'Jun 2016', 'Jul 2016', 'Aug 2016', 'Sep 2016', 'Oct 2016', 'Nov 2016', 'Dec 2016'],
        ['First Test Document', '', '10.7916/ALICE', '08/07/2018', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '2', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Second Test Document', '', '10.7916/TESTDOC5', '08/07/2018', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        [nil, nil, nil, 'Totals:', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '2', '0', '0', '0', '0', '0', '0', '0', '0']

      ]
    end
    let(:usage_stats) do
      AcademicCommons::Metrics::UsageStatistics.new(
        solr_request, Time.zone.parse('Jan 2015'), Time.zone.parse('Dec 2016'),
        order_by: 'views', include_zeroes: true, per_month: true
      )
    end

    before do
      FactoryBot.create(:view_stat, at_time: Time.zone.parse('Jan 15, 2015'))
      FactoryBot.create(:view_stat, at_time: Time.zone.parse('March 9, 2016'))
      FactoryBot.create(:download_stat, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:download_stat, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:streaming_stat, at_time: Time.zone.parse('May 3, 2015'))

      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'creates the expected csv' do
      csv = usage_stats.month_by_month_csv
      expect(CSV.parse(csv)).to match expected_csv
    end
  end

  describe '#item' do
    subject(:usage_stats) do
      AcademicCommons::Metrics::UsageStatistics.new(
        solr_request, Date.parse('Dec 2015'), Date.parse('Apr 2016'), per_month: true
      )
    end

    before do
      FactoryBot.create(:view_stat, at_time: Date.parse('Jan 15, 2016'))
      FactoryBot.create(:view_stat, at_time: Date.parse('March 9, 2016'))
      FactoryBot.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryBot.create(:download_stat, at_time: Date.parse('April 2, 2016'))
      FactoryBot.create(:streaming_stat, at_time: Date.parse('May 3, 2015'))

      allow(Blacklight.default_index).to receive(:search)
        .with(solr_params).and_return(solr_response)
    end

    it 'return correct value for view period stats' do
      expect(usage_stats.item(doi).get_stat(Statistic::VIEW, 'Period')).to be 2
    end

    it 'returns correct value for view month stats' do
      expect(usage_stats.item(doi).get_stat(Statistic::VIEW, 'Jan 2016')).to be 1
    end

    it 'returns correct value of Lifetime download stats' do
      expect(usage_stats.item(doi).get_stat(Statistic::DOWNLOAD, 'Lifetime')).to be 2
    end

    it 'returns correct value of download April 2016 stats' do
      expect(usage_stats.item(doi).get_stat(Statistic::DOWNLOAD, 'Apr 2016')).to be 2
    end

    it 'returns error if month and year are not part of the period' do
      expect {
        usage_stats.item(doi).get_stat(Statistic::VIEW, 'May 2017')
      }.to raise_error 'View May 2017 not part of stats. Check parameters.'
    end

    it 'returns error if id not part of results' do
      expect {
        usage_stats.item('actest:134').get_stat(Statistic::VIEW, 'Jan 2016')
      }.to raise_error 'Could not find actest:134'
    end

    it 'returns 0 if id not present, but id part of results' do
      expect(usage_stats.item('10.7916/TESTDOC5').get_stat(Statistic::VIEW, 'Jan 2016')).to be 0
    end
  end

  describe '#most_downloaded_asset' do
    subject(:most_downloaded_asset) do
      usage_stats.instance_eval do
        most_downloaded_asset(
          SolrDocument.new(
            'id' => '10.7916/ALICE', 'title_ssi' => 'Second Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => '10.7916/ALICE', 'publisher_doi_ssi' => '', 'fedora3_pid_ssi' => 'actest:1', 'genre_ssim' => ''
          )
        )
      end
    end

    let(:asset1_doi) { '10.7916/TESTDOC2' }
    let(:asset2_doi) { '10.7916/TESTDOC4' }

    it 'returns error when identifier not provided' do
      expect {
        usage_stats.instance_eval { most_downloaded_asset }
      }.to raise_error ArgumentError
    end

    context 'when item has one asset' do
      it 'returns only asset' do
        expect(most_downloaded_asset).to eql asset1_doi
      end
    end

    context 'when item has more than one asset' do
      before do
        FactoryBot.create(:download_stat)
        FactoryBot.create(:download_stat, identifier: asset2_doi)
        FactoryBot.create(:download_stat, identifier: asset2_doi)
      end

      it 'returns most downloaded' do
        expect(most_downloaded_asset).to eql asset2_doi
      end
    end

    context 'when item\'s asset has never been downloaded' do
      it 'returns first pid' do
        expect(most_downloaded_asset).to eql asset1_doi
      end
    end
  end

  describe '.time_period' do
    subject(:time_period) { usage_stats.instance_eval { time_period } }

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
