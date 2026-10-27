# frozen_string_literal: true

FactoryBot.define do
  factory :data_feed do
    key { 'data_feed_key' }
    search_fields { { key: 'value' } }
  end
end
