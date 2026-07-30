require 'rails_helper'
require 'json'

RSpec.describe 'mcp server', type: :request do
  before { host! 'localhost' }

  let!(:token) { FactoryBot.create(:token, scope: Token::API) }
  let(:body) do
    JSON.generate(
      'jsonrpc' => '2.0',
      'id' => 1,
      'method' => 'tools/call',
      'params' => {
        'name' => 'RecordsTool',
        'arguments' => {
          'search_type' => 'keyword',
          'q' => 'Alice',
          'per_page' => 10
        }
      }
    )
  end
  let(:headers) do
    {
      'Authorization': "Bearer #{token.token}",
      "Content-Type": 'application/json'
    }
  end
  let(:bad_headers) do
    {
      'Authorization': 'Bearer not_a_token',
      "Content-Type": 'application/json'
    }
  end

  it 'exposes the mcp server at /mcp' do
    post '/mcp', params: body, headers: headers
    expect(response).to have_http_status(:success)
  end

  it 'returns the search result' do
    post '/mcp', params: body, headers: headers
    expect(response.body).to include("Alice's Adventures in Wonderland")
  end

  it 'returns 401 with a bad token' do
    post '/mcp', params: body, headers: bad_headers
    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns 401 with a no token' do
    post '/mcp', params: body, headers: { "Content-Type": 'application/json' }
    expect(response).to have_http_status(:unauthorized)
  end
end
