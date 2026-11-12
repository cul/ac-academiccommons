# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog controller actions', type: :request do
  describe '/search' do
    it 'returns a 200 status when valid search params are supplied' do
      get '/search?per_page=20&sort=Published+Latest'
      expect(response.status).to eq(200)
    end

    it 'ignores bad sort values' do
      get '/search?per_page=20&sort=zzz'
      expect(response.status).to eq(200)
    end

    # pending - ACHYDRA-842
    xit 'validates paging values' do
      get '/search?per_page=Bad+Value&sort=Published+Latest'
      expect(response.status).to eq(400)
    end

    it 'returns x-robots-tag none in headers' do
      get '/search?per_page=20&sort=Published+Latest'
      expect(response.headers['X-Robots-Tag']).to eq('none')
    end
  end

  describe '/show' do
    it 'does not return x-robots-tag none in headers' do
      get '/doi/10.7916/ALICE'
      expect(response.headers['X-Robots-Tag']).to be_nil
    end

    describe 'view statistics' do
      # Requests without a user agent are treated as bots and never recorded.
      let(:headers) do
        { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' }
      end

      it 'records a view for an existing item' do
        expect {
          get '/doi/10.7916/ALICE', headers: headers
        }.to change { Statistic.where(event: Statistic::VIEW, identifier: '10.7916/ALICE').count }.by(1)

        expect(response).to have_http_status(:ok)
      end

      it 'does not record a view for an id that does not resolve to an item' do
        expect {
          get '/doi/10.7916/D8%E2%80%A6', headers: headers
        }.not_to change(Statistic, :count)

        expect(response).to have_http_status(:not_found)
      end

      it 'does not record a view for a bot' do
        expect {
          get '/doi/10.7916/ALICE', headers: { 'User-Agent' => 'Googlebot/2.1 (+http://www.google.com/bot.html)' }
        }.not_to change(Statistic, :count)
      end
    end
  end
end
