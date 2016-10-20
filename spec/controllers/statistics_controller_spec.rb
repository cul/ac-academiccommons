require 'rails_helper'

describe StatisticsController, :type => :controller do
  let(:pid) { 'actest:1' }

  before do
    @non_admin = double(User)
    allow(@non_admin).to receive(:admin).and_return(false)
    @admin = double(User)
    allow(@admin).to receive(:admin).and_return(true)
  end
  # require_admin
  [:all_author_monthlies, :author_monthly, :search_history, :school_docs_size,
   :single_pid_count, :single_pid_stats, :school_stats, :stats_by_event,
   :docs_size_by_query_facets, :facetStatsByEvent, :common_statistics_csv,
   :generic_statistics, :school_statistics, :send_csv_report].each do |action|
    describe action.to_s do # rspec wants a String here
      context "without being logged in" do
        before do
          allow(controller).to receive(:current_user).and_return(nil)
        end
        it "redirects to new_user_session_path" do
          get action
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(new_user_session_url)
        end
      end
      context "logged in as a non-admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@non_admin)
        end
        it "fails" do
          get action
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(access_denied_url)
        end
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
      before do
        allow(controller).to receive(:current_user).and_return(@non_admin)
        allow(controller).to receive(:statistical_reporting)
      end
      it "succeeds" do
        get :unsubscribe_monthly
        expect(response.status).to eql(302)
        expect(response.headers['Location']).to eql(root_url)
      end
    end
  end

  # require_user
  [:usage_reports, :statistical_reporting].each do |action|
    describe action.to_s do # rspec wants a String here
      context "without being logged in" do
        before do
          allow(controller).to receive(:current_user).and_return(nil)
        end
        it "redirects to new_user_session_path" do
          get action
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(new_user_session_url)
        end
      end
      context "logged in as a non-admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@non_admin)
          allow(controller).to receive(:statistical_reporting)
        end
        it "succeeds" do
          get action
          expect(response.status).to eql(200)
        end
      end
    end
  end

  describe 'single_pid_count' do
    before do
      allow(controller).to receive(:current_user).and_return(@admin)
      get :single_pid_count, :pid => 'actest:1'
    end

    it 'returns correct number of docs' do
      expect(response.body).to eq '1'
    end
  end

  describe 'single_pid_stats' do
    let(:action) { :single_pid_stats }

    before do
      allow(controller).to receive(:current_user).and_return(@admin)
    end

    it 'returns correct number of views' do
      get action, :pid => pid, :event => 'View'
      expect(response.body).to eq '0'
    end

    it 'returns correct number of downloads' do
      get action, :pid => pid, :event => 'Download'
      expect(response.body).to eq '0'
    end

    it 'returns correct number of streams' do
      get action, :pid => pid, :event => 'Streaming'
      expect(response.body).to eq '0'
    end

    it 'numbers of view increment with item viewed'
  end
end
