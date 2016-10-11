require 'spec_helper'

RSpec.describe DepositController, :type => :controller do
  describe 'POST submit' do

    context "when user has a uni" do
      before do
        post :submit, acceptedAgreement: 'agree',
          uni: 'xxx123', name: "Jane Doe", :'AC-agreement-version' => '1.1',
          email: 'xxx123@columbia.edu', title: 'Test Deposit', author: 'Jane Doe',
          abstr: 'Blah blah blah', file: fixture_file_upload('/test_file.txt')
      end

      it 'response is successful' do
        expect(response).to have_http_status :success
      end

      it 'emails about submission' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.to).to eq Rails.application.config.emails['mail_deposit_recipients']
        expect(email.subject).to eq 'SD xxx123 - Test Deposit'
        expect(email.attachments[0].filename).to eq 'test_file.txt'
      end

      it 'creates a deposit record' do
        expect(Deposit.count).to eq 1
        expect(Deposit.first.name).to eq 'Jane Doe'
        expect(Deposit.first.uni).to eq 'xxx123'
        expect(File.basename(Deposit.first.file_path)).to eq 'test_file.txt'
      end
    end

    context "when user does not have a uni" do
      before do
        post :submit, acceptedAgreement: 'agree', name: "Jane Doe",
          :'AC-agreement-version' => '1.1', email: 'xxx123@columbia.edu',
          title: 'Test Deposit', author: 'Jane Doe',
          abstr: 'Blah blah blah', file: fixture_file_upload('/test_file.txt')
      end

      it 'response is successful' do
        expect(response).to have_http_status :success
      end

      it 'creates a deposit record' do
        expect(Deposit.count).to eq 1
        expect(Deposit.first.uni).to eq nil
        expect(Deposit.first.email).to eq 'xxx123@columbia.edu'
      end
    end
  end
end
