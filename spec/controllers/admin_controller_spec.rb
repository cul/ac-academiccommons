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
  [:show_deposit, :download_deposit_file].each do |action|
    describe action.to_s do # rspec wants a String here
      before do
        @deposit = double(Deposit)
        @params = {:id => 'foo'}
        allow(Deposit).to receive(:find).with(@params[:id]).and_return(@deposit)
        this_file = __FILE__.sub(Rails.root.to_s + '/','')
        allow(@deposit).to receive(:file_path).and_return(this_file)
      end
      context "without being logged in" do
        before do
          allow(controller).to receive(:current_user).and_return(nil)
        end
        it "redirects to new_user_session_path" do
          get action, @params
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(new_user_session_url)
        end
      end
      context "logged in as a non-admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@non_admin)
        end
        it "fails" do
          get action, @params
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(access_denied_url)
        end
      end
      context "logged in as an admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@admin)
        end
        it "succeeds" do
          get action, @params
          expect(response.status).to eql(200)
        end
      end
    end
    describe "ingest" do
      context "without being logged in" do
        before do
          allow(controller).to receive(:current_user).and_return(nil)
        end
        it "redirects to new_user_session_path" do
          get :ingest, @params
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(new_user_session_url)
        end
      end
      context "logged in as a non-admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@non_admin)
        end
        it "fails" do
          get :ingest, @params
          expect(response.status).to eql(302)
          expect(response.headers['Location']).to eql(access_denied_url)
        end
      end
      context "logged in as an admin user" do
        before do
          allow(controller).to receive(:current_user).and_return(@admin)
          expect(controller).to receive(:processIndexing)
        end
        it "succeeds" do
          get :ingest, @params
          expect(response.status).to eql(200)
        end
      end
    end
  end
end
