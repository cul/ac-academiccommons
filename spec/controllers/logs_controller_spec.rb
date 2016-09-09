require 'spec_helper'

describe LogsController, :type => :controller do
  before do
    @non_admin = double(User)
    allow(@non_admin).to receive(:admin).and_return(false)
  end
  [:ingest_history, :all_author_monthly_reports_history, :log_form].each do |action|
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
end