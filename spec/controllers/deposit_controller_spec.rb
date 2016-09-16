require 'spec_helper'

RSpec.describe DepositController, :type => :controller do
  describe 'POST submit' do
    before :example do
      post :submit, acceptedAgreement: 'agree',
        uni: 'xxx123', name: "Jane Doe", :'AC-agreement-version' => '1.1',
        email: 'xxx123@columbia.edu', title: 'Test Deposit', authors: 'Jane Doe',
        abstract: 'Blah blah blah', file: fixture_file_upload('/test_file.txt')
    end

    it 'response is successful' do
      expect(response).to have_http_status :success
    end

    it 'emails about submission' do
      email = ActionMailer::Base.deliveries.pop
      expect(email.to).to eq Rails.application.config.emails['mail_deposit_recipients']
      expect(email.subject).to eq 'New Academic Commons Deposit Request'
    end
  end
end
