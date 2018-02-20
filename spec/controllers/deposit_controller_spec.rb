require 'rails_helper'

RSpec.describe DepositController, type: :controller do

  describe 'POST submit' do
    context 'when user has a uni' do
      before do
        post :submit, acceptedAgreement: 'agree',
          uni: 'xxx123', name: 'Jane Doe', :'AC-agreement-version' => '1.1',
          email: 'xxx123@columbia.edu', title: 'Test Deposit', author: 'Jane Doe',
          abstr: 'Blah blah blah', file: fixture_file_upload('/test_file.txt')
      end

      after do # Deleting file created by deposit.
        FileUtils.rm(File.join(Rails.root, Deposit.first.file_path))
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
        expect(Deposit.first.file_path).to eq 'data/self-deposit-uploads/xxx123/test_file.txt'
      end

      it 'create a agreement record' do
        expect(Agreement.count).to eq 1
        expect(Agreement.first.uni).to eq 'xxx123'
      end
    end

    context 'when user does not have a uni' do
      before do
        post :submit, acceptedAgreement: 'agree', name: 'Jane Doe',
          :'AC-agreement-version' => '1.1', email: 'xxx123@columbia.edu',
          title: 'Test Deposit', author: 'Jane Doe',
          abstr: 'Blah blah blah', file: fixture_file_upload('/test_file.txt')
      end

      after do # Deleting file created by deposit.
        FileUtils.rm(File.join(Rails.root, Deposit.first.file_path))
      end

      it 'response is successful' do
        expect(response).to have_http_status :success
      end

      it 'creates a deposit record' do
        expect(Deposit.count).to eq 1
        expect(Deposit.first.uni).to eq nil
        expect(Deposit.first.email).to eq 'xxx123@columbia.edu'
      end

      it 'create a agreement record' do
        expect(Agreement.count).to eq 1
        expect(Agreement.first.name).to eq 'Jane Doe'
      end

      context 'when the same file is deposited twice' do
        before do
          post :submit, acceptedAgreement: 'agree', name: 'Jane Doe',
            :'AC-agreement-version' => '1.1', email: 'xxx123@columbia.edu',
            title: 'Test Deposit 2', author: 'Jane Doe',
            abstr: 'Blah blah blah', file: fixture_file_upload('/test_file.txt')
        end

        after do
          FileUtils.rm(File.join(Rails.root, Deposit.last.file_path))
        end

        it 'creates a second deposit record' do
           expect(Deposit.count).to eq 2
           expect(Deposit.last.title).to eq 'Test Deposit 2'
        end

        it 'does not override previous file' do
          expect(Deposit.last.file_path).to eq 'data/self-deposit-uploads/test_file-1.txt'
        end
      end
    end
  end
end
