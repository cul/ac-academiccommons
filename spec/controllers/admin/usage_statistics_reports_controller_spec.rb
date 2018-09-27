require 'rails_helper'

describe Admin::UsageStatisticsReportsController, type: :controller, integration: true do
  let(:pid) { 'actest:1' }
  let(:params) do
    {
      usage_statistics_reports_form: {
        time_period: 'lifetime',
        display: 'summary',
        order: 'Title',
        filters: [{ field: 'author_ssim', value: 'Carroll, Lewis' }]
      }
    }
  end

  describe 'GET new' do
    include_examples 'authorization required' do
      let(:http_request) { get :new }
    end
  end

  describe 'POST create' do
    context 'html' do
      include_examples 'authorization required' do
        let(:http_request) do
          post :create, params: params
        end
      end
    end

    context 'csv' do
      include_examples 'authorization required' do
        let(:http_request) do
          post :create, params: params, format: :csv
        end
      end
    end
  end

  # Needs to be implemented
  describe 'POST email' do
    let(:email_params) do
      {
        email: {
          to: 'researcher@example.com',
          subject: 'Testing Usage Statistics',
          body: 'Dear Researcher, \n\nHere are the statistics you requests.\n\nBest,\n\nAcademic Commons Staff',
          csv: false
        }
      }
    end

    include_examples 'authorization required' do
      let(:http_request) do
        post :email, params: params.merge(email_params), format: :json
      end
    end

    context 'when admin makes request' do
      include_context 'admin user for controller'

      before do
        post :email, params: params.merge(email_params), format: :json
      end

      it 'sends email' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.to).to include 'researcher@example.com'
        expect(email.from).to include 'ac@columbia.edu'
      end
    end
  end
end
