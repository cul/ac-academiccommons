# frozen_string_literal: true
FactoryBot.define do
  factory :featured_search_value do
    factory :libraries_search_value do
      association :featured_search
      value { 'Libraries' }
    end
  end
end
