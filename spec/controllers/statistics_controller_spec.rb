require 'rails_helper'

describe StatisticsController, :type => :controller do
  let(:pid) { 'actest:1' }

  #:statistical_reporting #require admin

  describe 'GET all_author_monthlies' do
    before do
      allow(EmailPreference).to receive(:find).and_return([])
    end

    include_examples 'authorization required' do
      let(:request) { get :all_author_monthlies }
    end
  end

  describe 'GET detail_report' do
    include_examples 'authorization required' do
      let(:request) { get :detail_report }
    end
  end

  describe 'GET school_docs_size' do
    include_examples 'authorization required' do
      let(:request) { get :school_docs_size, :school => 'Columbia University' }
    end
  end

  describe 'GET single_pid_count' do
    include_examples 'authorization required' do
      let(:request) { get :single_pid_count, :pid => 'actest:1' }
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
      let(:request) { get :single_pid_stats }
    end

    context 'when admin user makes request' do
      include_context 'mock admin user'

      it 'returns correct number of views' do
        get :single_pid_stats, :pid => pid, :event => 'View'
        expect(response.body).to eq '0'
      end

      it 'returns correct number of downloads' do
        get :single_pid_stats, :pid => pid, :event => 'Download'
        expect(response.body).to eq '0'
      end

      it 'returns correct number of streams' do
        get :single_pid_stats, :pid => pid, :event => 'Streaming'
        expect(response.body).to eq '0'
      end

      it 'numbers of view increment with item viewed'
    end
  end

  describe 'GET school_stats' do
    include_examples 'authorization required' do
      let(:request) { get :school_stats, :school => 'Columbia University' }
    end
  end

  describe 'GET stats_by_event' do
    include_examples 'authorization required' do
      let(:request) { get :stats_by_event, :event => 'View' }
    end
  end

  describe 'GET docs_size_by_query_facets' do
    include_examples 'authorization required' do
      let(:request) { get :docs_size_by_query_facets }
    end
  end

  describe 'GET facetStatsByEvent' do
    include_examples 'authorization required' do
      let(:request) { get :facetStatsByEvent }
    end
  end

  describe 'GET common_statistics_csv' do
    include_examples 'authorization required' do
      let(:request) { get :common_statistics_csv, :f => {"author_facet"=>["Carroll, Lewis"]} }
    end
  end

  describe 'GET generic_statistics' do
    include_examples 'authorization required' do
      let(:request) { get :generic_statistics }
    end
  end

  describe 'GET school_statistics' do
    include_examples 'authorization required' do
      let(:request) { get :school_statistics }
    end
  end

  describe 'GET send_csv_report' do
    include_examples 'authorization required' do
      let(:request) {
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

  # require_user
  describe 'unsubscribe_monthly' do
    context "without being logged in" do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it "redirects to new_user_session_path" do
        get :unsubscribe_monthly
        expect(response.status).to eql(302)
        expect(response.headers['Location']).to eql(new_user_session_url)
      end
    end
    context "logged in as a non-admin user" do
      include_context 'mock non-admin user'

      it "succeeds" do
        get :unsubscribe_monthly
        expect(response.status).to eql(302)
        expect(response.headers['Location']).to eql(root_url)
      end
    end
  end
end
