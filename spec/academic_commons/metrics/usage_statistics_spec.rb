require 'rails_helper'

RSpec.describe AcademicCommons::Metrics::UsageStatistics do
  let(:uni) { 'abc123' }
  let(:item_identifier) { '10.7916/ALICE' }
  let(:item_fedora_pid) { 'actest:1' }
  let(:other_item_identifier) { '10.7916/TESTDOC5' }
  let(:other_item_fedora_pid) { 'actest:5' }
  let(:open_asset_identifier) { '10.7916/TESTDOC2' }
  let(:open_asset_fedora_pid) { 'actest:2' }
  let(:embargoed_asset_identifier) { '10.7916/TESTDOC10' }
  let(:empty_response) { { 'response' => { 'docs' => [] } } }
  let(:usage_stats) { described_class.new.calculate_lifetime }
  let(:any_by_author_params) { { q: nil, fq: ["author_uni_ssim:\"#{uni}\""] } }
  let(:any_by_author_response) do
    wrap_solr_response_data(
      'response' => {
        'docs' => [
          { 'id' => open_asset_identifier, 'fedora3_pid_ssi' => 'actest:2', 'title_ssi' => 'Second Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => open_asset_identifier, 'genre_ssim' => '', 'publisher_doi_ssi' => '' },
          { 'id' => item_identifier, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => item_identifier, 'fedora3_pid_ssi' => item_fedora_pid, 'genre_ssim' => '', 'publisher_doi_ssi' => '' },
          { 'id' => embargoed_asset_identifier, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => embargoed_asset_identifier, 'fedora3_pid_ssi' => 'actest:10', 'genre_ssim' => '', 'publisher_doi_ssi' => '',
            'free_to_read_start_date_ssi' => Date.current.tomorrow.strftime('%Y-%m-%d') }
        ]
      }
    )
  end

  let(:item_by_author_params) do
    {
      rows: 100_000, sort: 'title_sort asc', q: nil, page: 1,
      fq: ["author_uni_ssim:\"#{uni}\"", 'has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
      fl: 'title_ssi,id,cul_doi_ssi,fedora3_pid_ssi,publisher_doi_ssi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
    }
  end
  let(:item_by_author_response) do
    wrap_solr_response_data(
      'response' => {
        'docs' => [
          { 'id' => item_identifier, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A', 'record_creation_dtsi' => '2018-08-07T03:40:22Z',
            'cul_doi_ssi' => item_identifier, 'fedora3_pid_ssi' => item_fedora_pid, 'publisher_doi_ssi' => '', 'genre_ssim' => '' },
          { 'id' => other_item_identifier, 'title_ssi' => 'Second Test Document', 'object_state_ssi' => 'A', 'record_creation_dtsi' => '2018-08-07T03:40:22Z',
            'cul_doi_ssi' => other_item_identifier, 'fedora3_pid_ssi' => other_item_fedora_pid, 'publisher_doi_ssi' => '', 'genre_ssim' => '' }
        ]
      }
    )
  end

  let(:assets_for_item_params) do
    {
      rows: 100_000, facet: false, qt: 'search',
      fq: ["cul_member_of_ssim:\"info:fedora/#{item_fedora_pid}\"", "object_state_ssi:\"A\""]
    }
  end
  let(:assets_for_item_response) do
    wrap_solr_response_data(
      'response' => {
        'docs' => [
          { 'id' => open_asset_identifier, 'fedora3_pid_ssi' => open_asset_fedora_pid, 'title_ssi' => 'Second Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => open_asset_identifier, 'genre_ssim' => '', 'publisher_doi_ssi' => '' },
          { 'id' => embargoed_asset_identifier, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => embargoed_asset_identifier, 'fedora3_pid_ssi' => 'actest:10', 'genre_ssim' => '', 'publisher_doi_ssi' => '',
            'free_to_read_start_date_ssi' => Date.current.tomorrow.strftime('%Y-%m-%d') }
        ]
      }
    )
  end

  let(:assets_for_other_item_params) do
    {
      rows: 100_000, facet: false, qt: 'search',
      fq: ["cul_member_of_ssim:\"info:fedora/#{other_item_fedora_pid}\"", "object_state_ssi:\"A\""]
    }
  end
  let(:assets_for_other_item_response) do
    wrap_solr_response_data(
      'response' => {
        'docs' => []
      }
    )
  end

  let(:list_items_params) do
    {
      rows: 100_000, sort: 'title_sort asc', page: 1,
      fq: ['has_model_ssim:"info:fedora/ldpd:ContentAggregator"'],
      fl: 'title_ssi,id,cul_doi_ssi,fedora3_pid_ssi,publisher_doi_ssi,genre_ssim,record_creation_dtsi,object_state_ssi,free_to_read_start_date_ssi'
    }
  end
  let(:list_items_response) do
    wrap_solr_response_data(
      'response' => {
        'docs' => [
          { 'id' => item_identifier, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => item_identifier, 'fedora3_pid_ssi' => item_fedora_pid, 'genre_ssim' => '', 'publisher_doi_ssi' => '' },
          { 'id' => other_item_identifier, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => other_item_identifier, 'fedora3_pid_ssi' => other_item_fedora_pid, 'genre_ssim' => '', 'publisher_doi_ssi' => '' }
        ]
      }
    )
  end

  before do
    allow(Blacklight.default_index).to receive(:search).with(any_by_author_params).and_return(any_by_author_response)
    allow(Blacklight.default_index).to receive(:search).with(item_by_author_params).and_return(item_by_author_response)
    allow(Blacklight.default_index).to receive(:search).with(assets_for_item_params).and_return(assets_for_item_response)
    allow(Blacklight.default_index).to receive(:search).with(assets_for_other_item_params).and_return(assets_for_other_item_response)
    allow(Blacklight.default_index).to receive(:search).with(list_items_params).and_return(list_items_response)
  end

  describe '.new' do
    let(:yesterday) { Date.current.in_time_zone - 1.day }
    context 'when requesting usage stats for author' do
      before do
        # Add records for a pid view and download
        FactoryBot.create(:view_stat, identifier: item_identifier, at_time: yesterday)
        FactoryBot.create(:view_stat, identifier: item_identifier, at_time: yesterday)
        FactoryBot.create(:download_stat, identifier: open_asset_identifier, at_time: yesterday)
        FactoryBot.create(:streaming_stat, identifier: item_identifier, at_time: yesterday)
      end

      context 'when requesting stats for an author with embargoed material' do
        subject(:usage_stats) do
          options = { solr_params: any_by_author_params }
          described_class.new(**options).calculate_lifetime
        end

        it 'removes embargoed material' do
          expect(usage_stats.count).to eq 2
          expect(usage_stats.find { |i| i.id == embargoed_asset_identifier }).to eq nil
        end

        it 'calculates stats for available material' do
          expect(usage_stats.total_for(Statistic::VIEW, :lifetime)).to eq 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, :lifetime)).to eq 1
        end
      end

      context 'when request lifetime stats' do
        let(:decade_ago) { Date.current.in_time_zone - 10.years }
        before do
          FactoryBot.create(:view_stat, at_time: decade_ago)
        end

        subject(:usage_stats) do
          described_class.new(
            solr_params: item_by_author_params, include_streaming: true
          ).calculate_lifetime
        end

        it 'returns correct results' do
          expect(usage_stats.map(&:document).map(&:to_h)).to eq item_by_author_response.documents.map(&:to_h)
        end

        it 'returns correct totals for lifetime' do
          expect(usage_stats.total_for(Statistic::VIEW, :lifetime)).to be 3
          expect(usage_stats.total_for(Statistic::DOWNLOAD, :lifetime)).to be 1
          expect(usage_stats.total_for(Statistic::STREAM, :lifetime)).to be 1
        end

        it 'returns error if period stats are requested' do
          expect {
            usage_stats.total_for(Statistic::VIEW, :period)
          }.to raise_error 'View period not part of stats. Check parameters.'
        end
      end

      context 'when requesting stats for current month' do
        subject(:usage_stats) do
          described_class.new(
            solr_params: item_by_author_params, start_date: Date.current - 1.month,
            end_date: Date.current, include_streaming: true
          ).calculate_lifetime.calculate_period
        end

        it 'returns correct results' do
          expect(subject.map(&:document).map(&:to_h)).to eq item_by_author_response.documents.map(&:to_h)
        end

        it 'returns correct totals' do
          expect(usage_stats.total_for(Statistic::VIEW, :period)).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, :period)).to be 1
          expect(usage_stats.total_for(Statistic::STREAM, :period)).to be 1
          expect(usage_stats.total_for(Statistic::VIEW, :lifetime)).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, :lifetime)).to be 1
          expect(usage_stats.total_for(Statistic::STREAM, :lifetime)).to be 1
        end
      end

      context 'when requesting stats for previous month' do
        subject(:usage_stats) do
          described_class.new(
            solr_params: item_by_author_params, start_date: Date.current - 2.months,
            end_date: Date.current - 1.month, include_streaming: true
          ).calculate_lifetime.calculate_period
        end

        it 'returns correct results' do
          expect(usage_stats.map(&:document).map(&:to_h)).to eq item_by_author_response.documents.map(&:to_h)
        end

        it 'returns correct totals' do
          expect(usage_stats.total_for(Statistic::VIEW, :period)).to be 0
          expect(usage_stats.total_for(Statistic::DOWNLOAD, :period)).to be 0
          expect(usage_stats.total_for(Statistic::STREAM, :period)).to be 0
          expect(usage_stats.total_for(Statistic::VIEW, :lifetime)).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, :lifetime)).to be 1
          expect(usage_stats.total_for(Statistic::STREAM, :lifetime)).to be 1
        end
      end

      context 'when requesting stats without streaming' do
        subject(:usage_stats) do
          described_class.new(
            solr_params: any_by_author_params, start_date: Date.current - 1.month,
            end_date: Date.current
          ).calculate_lifetime.calculate_period
        end

        it 'returns correct totals' do
          expect(usage_stats.total_for(Statistic::VIEW, :period)).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, :period)).to be 1
          expect(usage_stats.total_for(Statistic::VIEW, :lifetime)).to be 2
          expect(usage_stats.total_for(Statistic::DOWNLOAD, :lifetime)).to be 1
        end
      end
    end
  end

  describe '#months_list' do
    let(:dates) do
      ['Dec 2015', 'Jan 2016', 'Feb 2016', 'Mar 2016', 'Apr 2016'].map { |d| Time.zone.parse(d) }
    end

    it 'returns correct list' do
      usage_stats = described_class.new(start_date: dates.first, end_date: dates.last).calculate_month_by_month
      result = usage_stats.instance_eval { months_list }
      expect(result).to eq dates
    end
  end

  describe '#period_csv' do
    let(:uni) { 'abc123' }
    let(:expected_csv) do
      [
        ['Period Covered by Report:', 'Jan 2015 - Dec 2016'],
        ['Raw Query:', '{:q=>nil, :fq=>["author_uni_ssim:\\"abc123\\""]}'],
        ['Order:', 'Period Views'],
        ['Report created by:', 'N/A'],
        ['Report created on:', Time.current.strftime('%Y-%m-%d')],
        ['Total number of items:', '2'],
        [],
        ['Title', 'Views', 'Downloads'],
        ['First Test Document', '2', '2'],
        ['Second Test Document', '0', '0'],
        ['Totals:', '2', '2']
      ]
    end
    let(:usage_stats) do
      described_class.new(
        solr_params: any_by_author_params, start_date: Time.zone.parse('Jan 2015'),
        end_date: Time.zone.parse('Dec 2016')
      ).calculate_period.order_by(:period, Statistic::VIEW)
    end

    before do
      FactoryBot.create(:view_stat, identifier: item_identifier, at_time: Time.zone.parse('Jan 15, 2015'))
      FactoryBot.create(:view_stat, identifier: item_identifier, at_time: Time.zone.parse('March 9, 2016'))
      FactoryBot.create(:view_stat, identifier: item_identifier, at_time: Time.zone.parse('Jan 7, 2017'))
      FactoryBot.create(:download_stat, identifier: open_asset_identifier, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:download_stat, identifier: open_asset_identifier, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:streaming_stat, identifier: item_identifier, at_time: Time.zone.parse('May 3, 2015'))
    end

    it 'creates the expected csv' do
      csv = usage_stats.period_csv
      expect(CSV.parse(csv)).to match expected_csv
    end
  end

  describe '#month_by_month_csv' do
    let(:expected_csv) do
      [
        ['Period Covered by Report:', 'Jan 2015 - Dec 2016'],
        ['Raw Query:', '{:q=>nil, :fq=>["author_uni_ssim:\\"abc123\\""]}'],
        ['Order:', 'Title'],
        ['Report created by:', 'N/A'],
        ['Report created on:', Time.current.strftime('%Y-%m-%d')],
        ['Total number of items:', '2'],
        [],
        ['VIEWS'],
        ['Title', 'Jan 2015', 'Feb 2015', 'Mar 2015', 'Apr 2015', 'May 2015', 'Jun 2015', 'Jul 2015', 'Aug 2015', 'Sep 2015', 'Oct 2015', 'Nov 2015', 'Dec 2015', 'Jan 2016', 'Feb 2016', 'Mar 2016', 'Apr 2016', 'May 2016', 'Jun 2016', 'Jul 2016', 'Aug 2016', 'Sep 2016', 'Oct 2016', 'Nov 2016', 'Dec 2016'],
        ['First Test Document', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Second Test Document', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Totals:', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '1', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        [],
        ['DOWNLOADS'],
        ['Title', 'Jan 2015', 'Feb 2015', 'Mar 2015', 'Apr 2015', 'May 2015', 'Jun 2015', 'Jul 2015', 'Aug 2015', 'Sep 2015', 'Oct 2015', 'Nov 2015', 'Dec 2015', 'Jan 2016', 'Feb 2016', 'Mar 2016', 'Apr 2016', 'May 2016', 'Jun 2016', 'Jul 2016', 'Aug 2016', 'Sep 2016', 'Oct 2016', 'Nov 2016', 'Dec 2016'],
        ['First Test Document', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '2', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Second Test Document', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'],
        ['Totals:', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '2', '0', '0', '0', '0', '0', '0', '0', '0']
      ]
    end
    let(:usage_stats) do
      described_class.new(
        solr_params: any_by_author_params, start_date: Time.zone.parse('Jan 2015'),
        end_date: Time.zone.parse('Dec 2016')
      ).calculate_month_by_month
    end

    before do
      FactoryBot.create(:view_stat, at_time: Time.zone.parse('Jan 15, 2015'))
      FactoryBot.create(:view_stat, at_time: Time.zone.parse('March 9, 2016'))
      FactoryBot.create(:download_stat, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:download_stat, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:streaming_stat, at_time: Time.zone.parse('May 3, 2015'))
    end

    it 'creates the expected csv' do
      csv = usage_stats.month_by_month_csv
      expect(CSV.parse(csv)).to match expected_csv
    end
  end

  describe '#item' do
    subject(:usage_stats) do
      described_class.new(
        solr_params: any_by_author_params, start_date: Time.zone.parse('Dec 2015'),
        end_date: Time.zone.parse('Apr 2016')
      ).calculate_lifetime.calculate_period.calculate_month_by_month
    end

    before do
      FactoryBot.create(:view_stat, identifier: item_identifier, at_time: Time.zone.parse('Jan 15, 2016'))
      FactoryBot.create(:view_stat, identifier: item_identifier, at_time: Time.zone.parse('March 9, 2016'))
      FactoryBot.create(:download_stat, identifier: open_asset_identifier, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:download_stat, identifier: open_asset_identifier, at_time: Time.zone.parse('April 2, 2016'))
      FactoryBot.create(:streaming_stat, identifier: item_identifier, at_time: Time.zone.parse('May 3, 2015'))
    end

    it 'return correct value for view period stats' do
      expect(usage_stats.item(item_identifier).get_stat(Statistic::VIEW, :period)).to be 2
    end

    it 'returns correct value for view month stats' do
      expect(usage_stats.item(item_identifier).get_stat(Statistic::VIEW, 'Jan 2016')).to be 1
    end

    it 'returns correct value of Lifetime download stats' do
      expect(usage_stats.item(item_identifier).get_stat(Statistic::DOWNLOAD, :lifetime)).to be 2
    end

    it 'returns correct value of download April 2016 stats' do
      expect(usage_stats.item(item_identifier).get_stat(Statistic::DOWNLOAD, 'Apr 2016')).to be 2
    end

    it 'returns error if month and year are not part of the period' do
      expect {
        usage_stats.item(item_identifier).get_stat(Statistic::VIEW, 'May 2017')
      }.to raise_error 'View May 2017 not part of stats. Check parameters.'
    end

    it 'returns error if id not part of results' do
      expect {
        usage_stats.item('actest:134').get_stat(Statistic::VIEW, 'Jan 2016')
      }.to raise_error 'Could not find actest:134'
    end

    it 'returns 0 if id not present, but id part of results' do
      expect(usage_stats.item(other_item_identifier).get_stat(Statistic::VIEW, 'Jan 2016')).to be 0
    end
  end

  describe '#most_downloaded_asset' do
    subject(:most_downloaded_asset) do
      usage_stats.instance_eval do
        most_downloaded_asset(
          # these must be literals to be evaluated in the instance context, but values
          # are taken from item_identifier and item_fedora_pid
          SolrDocument.new(
            'id' => '10.7916/ALICE', 'title_ssi' => 'Second Test Document', 'object_state_ssi' => 'A',
            'cul_doi_ssi' => '10.7916/ALICE', 'publisher_doi_ssi' => '', 'fedora3_pid_ssi' => 'actest:1', 'genre_ssim' => ''
          )
        )
      end
    end

    let(:other_open_asset_identifier) { '10.7916/TESTDOC4' }
    let(:other_open_asset_fedora_pid) { 'actest:5' }

    it 'returns error when identifier not provided' do
      expect {
        usage_stats.instance_eval { most_downloaded_asset }
      }.to raise_error ArgumentError
    end

    context 'when item has one asset' do
      it 'returns only asset' do
        expect(most_downloaded_asset).to eql open_asset_identifier
      end
    end

    context 'when item has more than one asset' do
      let(:assets_for_item_response) do
        wrap_solr_response_data(
          'response' => {
            'docs' => [
              { 'id' => open_asset_identifier, 'fedora3_pid_ssi' => open_asset_fedora_pid, 'title_ssi' => 'Second Test Document', 'object_state_ssi' => 'A',
                'cul_doi_ssi' => open_asset_identifier, 'genre_ssim' => '', 'publisher_doi_ssi' => '' },
              { 'id' => other_open_asset_identifier, 'title_ssi' => 'First Test Document', 'object_state_ssi' => 'A',
                'cul_doi_ssi' => other_open_asset_identifier, 'fedora3_pid_ssi' => other_open_asset_fedora_pid, 'genre_ssim' => '', 'publisher_doi_ssi' => '',
                'free_to_read_start_date_ssi' => Date.current.tomorrow.strftime('%Y-%m-%d') }
            ]
          }
        )
      end
      before do
        FactoryBot.create(:download_stat, identifier: open_asset_identifier)
        FactoryBot.create(:download_stat, identifier: other_open_asset_identifier)
        FactoryBot.create(:download_stat, identifier: other_open_asset_identifier)
      end

      it 'returns most downloaded' do
        expect(most_downloaded_asset).to eql other_open_asset_identifier
      end
    end

    context 'when item\'s asset has never been downloaded' do
      it 'returns first asset doi' do
        expect(most_downloaded_asset).to eql open_asset_identifier
      end
    end
  end

  describe '.time_period' do
    subject(:time_period) { usage_stats.instance_eval { time_period } }

    context 'when calculating period stats' do
      let(:usage_stats) { described_class.new(solr_params: item_by_author_params, start_date: Time.zone.parse('Jan 2015'), end_date: Time.zone.parse('Dec 2016')).calculate_period }

      it { is_expected.to eq 'Jan 2015 - Dec 2016' }
    end

    context 'when only calculating lifetime stats' do
      let(:usage_stats) { described_class.new(solr_params: item_by_author_params).calculate_lifetime }

      it { is_expected.to eq 'Lifetime' }
    end

    context 'when stats are for one month' do
      let(:date) { Date.current }
      let(:usage_stats) { described_class.new(solr_params: item_by_author_params, start_date: date, end_date: date).calculate_period }

      it { is_expected.to eq date.strftime('%b %Y') }
    end
  end
end
