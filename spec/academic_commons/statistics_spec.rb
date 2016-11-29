require 'rails_helper'

RSpec.describe AcademicCommons::Statistics do
  let(:uni) { 'abc123' }
  let(:pid) { 'actest:1' }

  let(:statistics) do
    class_rig = Class.new
    class_rig.class_eval do
      include AcademicCommons::Statistics
      def repository; end
    end
    c = class_rig.new
    allow(c).to receive(:repository).and_return(Blacklight.default_index)
    c
  end

  describe '.get_author_stats' do
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
          expect(@download_ids).to match(
            "#{pid}" => ['actest:2']
          )
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

  describe '.make_solr_request'
end
