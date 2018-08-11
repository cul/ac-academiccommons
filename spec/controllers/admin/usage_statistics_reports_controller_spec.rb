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
end
