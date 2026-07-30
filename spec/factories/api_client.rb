# frozen_string_literal: true

FactoryBot.define do
  factory :api_client, class: 'APIClient' do
    name { 'Test Service' }
    description { 'Service that queries the AC API' }
    contact_email { 'ta123@columbia.edu' }
  end
end
