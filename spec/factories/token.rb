# frozen_string_literal: true

FactoryBot.define do
  factory :token, class: 'Token' do
    scope { Token::DATAFEED }
    sequence(:token) { |n| "token-#{n}-value" }
    association :authorizable, factory: :api_client, strategy: :create
  end

  factory :mcp_token, class: 'Token' do
    scope { Token::MCP }
    token { 'mcp-token-value' }
    association :authorizable, factory: :user, strategy: :create
  end
end
