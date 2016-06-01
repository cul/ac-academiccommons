require 'spec_helper'

describe AdminController, :type => :controller do
  before do
    @non_admin = double(User)
    allow(@non_admin).to receive(:admin).and_return(false)
    @admin = double(User)
    allow(@admin).to receive(:admin).and_return(true)
  end
  # these actions do not require an ID param
  [:edit_alert_message, :edit_home_page, :deposits,
   :agreements, :student_agreements].each do |action|
    describe action do
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
      context "logged in as an admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@admin)
        end
        it "succeeds" do
          get action
          expect(response.status).to eql(200)
        end
      end
    end
  end
end
