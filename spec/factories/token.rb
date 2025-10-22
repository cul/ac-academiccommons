# frozen_string_literal: true

FactoryBot.define do
  factory :token, class: 'Token' do
    scope { Token::DATAFEED }
    token { 'token-value' }
    association :authorizable, factory: :api_client, strategy: :create
  end
end
