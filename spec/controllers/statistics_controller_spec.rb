require 'rails_helper'

describe StatisticsController, type: :controller, integration: true do
  let(:pid) { 'actest:1' }

  describe 'GET detail_report' do
    include_examples 'authorization required' do
      let(:http_request) { get :detail_report }
    end
  end

  describe 'GET total_usage_stats' do
    context 'without being logged in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        get :total_usage_stats, params: { format: :json }
      end

      it 'returns 403' do # Can't redirect because its a json request.
        expect(response.status).to be 403
      end
    end

    context 'logged in as a non-admin user' do
      include_context 'non-admin user'

      it 'fails' do
        expect {
          get :total_usage_stats, params: { format: :json }
        }.to raise_error CanCan::AccessDenied
      end
    end

    context 'when admin user makes a request' do
      include_context 'admin user'

      before :each do
        FactoryBot.create(:view_stat)
        FactoryBot.create(:download_stat)
        FactoryBot.create(:streaming_stat)
      end

      subject { get :total_usage_stats, params: { q: "{!raw f=fedora3_pid_ssi}#{pid}", format: :json } }

      it 'return correct json response' do
        json = JSON.parse(subject.body)
        expect(json).to include(
          'view' => 1,
          'download' => 1,
          'streaming' => 1,
          'records' => 1
        )
      end
    end
  end

  describe 'GET common_statistics_csv' do
    include_examples 'authorization required' do
      let(:http_request) { get :common_statistics_csv, params: { f: { 'author_ssim' => ['Carroll, Lewis'] } } }
    end
  end

  describe 'GET generic_statistics' do
    include_examples 'authorization required' do
      let(:http_request) { get :generic_statistics }
    end
  end

  describe 'GET school_statistics' do
    include_examples 'authorization required' do
      let(:http_request) { get :school_statistics }
    end
  end

  describe 'GET send_csv_report' do
    include_examples 'authorization required' do
      let(:http_request) do
        get :send_csv_report,
            params: {
              f: { 'author_ssim' => ['Carroll, Lewis'] },
              email_to: 'example@example.com',
              email_from: 'me@example.com'
            }
      end
    end

    context 'when admin makes request' do
      include_context 'admin user'

      before do
        get :send_csv_report,
            params: {
              f: { 'author_ssim' => ['Carroll, Lewis.'] },
              email_to: 'example@example.com',
              email_from: 'me@example.com'
            }
      end

      it 'sends email' do
        email = ActionMailer::Base.deliveries.pop
        expect(email.to).to include 'example@example.com'
        expect(email.from).to include 'me@example.com'
      end
    end
  end
end
