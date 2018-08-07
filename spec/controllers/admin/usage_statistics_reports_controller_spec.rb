require 'rails_helper'

describe Admin::UsageStatisticsReportsController, type: :controller, integration: true do
  let(:pid) { 'actest:1' }
  let(:params) do
    {
      usage_statistics_reports_form: {
        date_range: 'lifetime',
        display: 'summary',
        order:   'title',
        filters: [{ field: 'author_ssim', value: 'Carroll, Lewis' }]
      }
    }
  end

  describe 'GET new' do
    include_examples 'authorization required' do
      let(:http_request) { get :new }
    end
  end

  describe 'GET csv' do
    include_examples 'authorization required' do
      let(:http_request) do
        get :csv, params: params
      end
    end
  end

  describe 'POST create' do
    include_examples 'authorization required' do
      let(:http_request) do
        post :create, params: params
      end
    end
  end

  # Needs to be implemented
  # describe 'GET email' do
  #   include_examples 'authorization required' do
  #     let(:http_request) do
  #       get :send_csv_report,
  #           params: {
  #             f: { 'author_ssim' => ['Carroll, Lewis'] },
  #             email_to: 'example@example.com',
  #             email_from: 'me@example.com'
  #           }
  #     end
  #   end
  #
  #   context 'when admin makes request' do
  #     include_context 'admin user'
  #
  #     before do
  #       get :send_csv_report,
  #           params: {
  #             f: { 'author_ssim' => ['Carroll, Lewis.'] },
  #             email_to: 'example@example.com',
  #             email_from: 'me@example.com'
  #           }
  #     end
  #
  #     it 'sends email' do
  #       email = ActionMailer::Base.deliveries.pop
  #       expect(email.to).to include 'example@example.com'
  #       expect(email.from).to include 'me@example.com'
  #     end
  #   end
  # end

  # Does not require user login.
  # describe 'GET unsubscribe_monthly' do
  #   let(:uni) { 'abc123' }
  #   context 'does not add email preference' do
  #     it 'when author missing' do
  #       get :unsubscribe_monthly, params: { chk: 'foo' }
  #       expect(EmailPreference.count).to eq 0
  #     end
  #
  #     it 'when chk missing' do
  #       get :unsubscribe_monthly, params: { author_id: 'foo' }
  #       expect(EmailPreference.count).to eq 0
  #     end
  #
  #     it 'when chk and author missing' do
  #       get :unsubscribe_monthly
  #       expect(EmailPreference.count).to eq 0
  #     end
  #   end
  #
  #   context 'when chk param is correctly signed' do
  #     before :each do
  #       get :unsubscribe_monthly, params: { author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate(uni) }
  #     end
  #
  #     it 'creates email preference' do
  #       expect(EmailPreference.count).to eq 1
  #     end
  #
  #     it 'unsubscribes user' do
  #       expect(EmailPreference.first.author).to eq uni
  #       expect(EmailPreference.first.monthly_opt_out).to be true
  #     end
  #
  #     it 'changes email preference' do
  #       EmailPreference.first.update!(monthly_opt_out: false)
  #       get :unsubscribe_monthly, params: { author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate(uni) }
  #       expect(EmailPreference.first.monthly_opt_out).to be true
  #     end
  #   end
  #
  #   context 'when check param is not correctly signed' do
  #     before(:each) do
  #       get :unsubscribe_monthly, params: { author_id: uni, chk: Rails.application.message_verifier(:unsubscribe).generate('abc') }
  #     end
  #
  #     it 'does not unsubscribe user' do
  #       expect(EmailPreference.count).to eq 0
  #     end
  #   end
  # end
end
