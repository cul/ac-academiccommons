require 'rails_helper'

RSpec.describe SwordDepositJob, type: :job do
  subject(:job) { described_class.perform_later(deposit) }

  let(:deposit) { FactoryBot.create(:deposit) }
  # TODO : secrets to credentials
  let(:credentials) { Rails.application.secrets.sword }

  # Freezing time because the generated METS file contains a timestamp.
  before { freeze_time }
  after  { travel_back }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(SwordDepositJob).with(deposit)
  end

  context 'when executing perform' do
    # turn on sending deposits to sword, turn off after all tests
    before { Rails.application.config.sending_deposits_to_sword = true }
    after { Rails.application.config.sending_deposits_to_sword = false }

    context 'when successful' do
      before do
        stub_request(:post, credentials[:url]).with(
          basic_auth: [credentials[:user], credentials[:password]],
          headers: { 'Content-Type' => 'application/zip' },
          body: deposit.sword_zip
        ).to_return(body: { item_pid: 'ac:00112233' }.to_json, status: 201)

        perform_enqueued_jobs { job }
        deposit.reload
      end

      it 'send email to administrator' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.subject).to eql 'SD Test Deposit'
        expect(email.to).to include 'example@columbia.edu'
        expect(email.html_part.body).to include 'Test Deposit'
      end

      it 'removes all files' do
        expect(deposit.files).to be_empty
      end

      it 'updates deposit record with hyacinth identifier' do
        expect(deposit.hyacinth_identifier).to eql 'ac:00112233'
      end
    end

    context 'when failure' do
      before do
        stub_request(:post, credentials[:url]).with(
          basic_auth: [credentials[:user], credentials[:password]],
          headers: { 'Content-Type' => 'application/zip' },
          body: deposit.sword_zip
        ).to_return(body: {}.to_json, status: 500)

        perform_enqueued_jobs { job }
        deposit.reload
      end

      it 'send email to developers' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.to).to include 'developers@library.columbia.edu'
        expect(email.subject).to eql 'Error Delivering SWORD Deposit'
        expect(email.html_part.body).to include 'Oops! A problem came up in Academic Commons.'
      end

      it 'does not remove files' do
        expect(deposit.files.count).to be 1
      end

      it 'does not hyacinth identifier' do
        expect(deposit.hyacinth_identifier).to be nil
      end
    end
  end
end
