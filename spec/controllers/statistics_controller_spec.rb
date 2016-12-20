require 'rails_helper'

describe StatisticsController, :type => :controller, integration: true do
  let(:pid) { 'actest:1' }

  #:statistical_reporting #require admin

  describe 'GET all_author_monthlies' do
    before do
      allow(EmailPreference).to receive(:find).and_return([])
    end

    include_examples 'authorization required' do
      let(:http_request) { get :all_author_monthlies }
    end
  end

  describe 'GET detail_report' do
    include_examples 'authorization required' do
      let(:http_request) { get :detail_report }
    end
  end

  describe 'GET school_docs_size' do
    include_examples 'authorization required' do
      let(:http_request) { get :school_docs_size, :school => 'Columbia University' }
    end
  end

  describe 'GET single_pid_count' do
    include_examples 'authorization required' do
      let(:http_request) { get :single_pid_count, :pid => 'actest:1' }
    end

    context 'when admin user makes request' do
      include_context 'mock admin user'

      it 'returns correct number of docs' do
        get :single_pid_count, :pid => 'actest:1'
        expect(response.body).to eq '1'
      end
    end
  end

  describe 'GET single_pid_stats' do
    include_examples 'authorization required' do
      let(:http_request) { get :single_pid_stats }
    end

    context 'when admin user makes request' do
      include_context 'mock admin user'

      before :each do
        FactoryGirl.create(:view_stat)
        FactoryGirl.create(:download_stat)
        FactoryGirl.create(:streaming_stat)
      end

      it 'returns correct number of views' do
        get :single_pid_stats, :pid => pid, :event => 'View'
        expect(response.body).to eq '1'
      end

      # TODO: This test does not pass because instead of querying solr id number
      # is increased from the aggregator pid. Only works if the prefix is a
      # two letter prefix.
      it 'returns correct number of downloads' do
        get :single_pid_stats, :pid => pid, :event => 'Download'
        expect(response.body).to eq '1'
      end

      it 'returns correct number of streams' do
        get :single_pid_stats, :pid => pid, :event => 'Streaming'
        expect(response.body).to eq '1'
      end

      it 'numbers of view increment with item viewed' do
        FactoryGirl.create(:view_stat)
        get :single_pid_stats, pid: pid, event: 'View'
        expect(response.body).to eq '2'
      end
    end
  end

  describe 'GET school_stats' do
    include_examples 'authorization required' do
      let(:http_request) { get :school_stats, :school => 'Columbia University' }
    end
  end

  describe 'GET stats_by_event' do
    include_examples 'authorization required' do
      let(:http_request) { get :stats_by_event, :event => 'View' }
    end

    context 'when admin user makes request' do
      include_context 'mock admin user'

      before :each do
        FactoryGirl.create(:view_stat)
        FactoryGirl.create(:download_stat)
      end

      it 'returns total number of views' do
        get :stats_by_event, event: 'View'
        expect(response.body).to eql '1'
      end

      it 'returns total number of downloads' do
        get :stats_by_event, event: 'Download'
        expect(response.body).to eql '1'
      end
    end
  end

  describe 'GET docs_size_by_query_facets' do
    include_examples 'authorization required' do
      let(:http_request) { get :docs_size_by_query_facets }
    end
  end

  describe 'GET facetStatsByEvent' do
    include_examples 'authorization required' do
      let(:http_request) { get :facetStatsByEvent }
    end
  end

  describe 'GET common_statistics_csv' do
    include_examples 'authorization required' do
      let(:http_request) { get :common_statistics_csv, :f => {"author_facet"=>["Carroll, Lewis"]} }
    end
  end

  describe 'GET generic_statistics' do
    include_examples 'authorization required' do
      let(:http_request) { get :generic_statistics }
    end
  end

  describe 'GET school_statistics' do
    include_examples 'authorization required' do
      let(:http_request) { get :school_statistics }
    end
  end

  describe 'GET send_csv_report' do
    include_examples 'authorization required' do
      let(:http_request) {
        get :send_csv_report, :f => {"author_facet"=>["Carroll, Lewis"]},
            :email_to => 'example@example.com', :email_from => 'me@example.com'
      }
    end

    context 'when admin makes request' do
      include_context 'mock admin user'

      before do
        get :send_csv_report, :f => {"author_facet"=>["Carroll, Lewis."]},
            :email_to => 'example@example.com', :email_from => 'me@example.com'
      end

      it 'sends email' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.to).to include 'example@example.com'
        expect(email.from).to include 'me@example.com'
      end
    end
  end

  # Does not require user login.
  describe 'unsubscribe_monthly' do
    let(:uni) { 'abc123' }
    context 'does not add email preference' do
      it 'when author missing' do
        get :unsubscribe_monthly, chk: 'foo'
        expect(EmailPreference.count).to eq 0
      end

      it 'when chk missing' do
        get :unsubscribe_monthly, author_id: 'foo'
        expect(EmailPreference.count).to eq 0
      end

      it 'when chk and author missing' do
        get :unsubscribe_monthly
        expect(EmailPreference.count).to eq 0
      end
    end

    context 'when chk param is correctly signed' do
      before :each do
        get :unsubscribe_monthly, author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate(uni)
      end

      it 'creates email preference' do
        expect(EmailPreference.count).to eq 1
      end

      it 'unsubscribes user' do
        expect(EmailPreference.first.author).to eq uni
        expect(EmailPreference.first.monthly_opt_out).to be true
      end

      it 'changes email preference' do
        EmailPreference.first.update!(monthly_opt_out: false)
        get :unsubscribe_monthly, author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate(uni)
        expect(EmailPreference.first.monthly_opt_out).to be true
      end
    end

    context 'when check param is not correctly signed' do
      before(:each) do
        get :unsubscribe_monthly, author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate('abc')
      end

      it 'does not unsubscribe user' do
        expect(EmailPreference.count).to eq 0
      end
    end
  end
end
