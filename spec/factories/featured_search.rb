# frozen_string_literal: true
FactoryBot.define do
  factory :featured_search do
    factory :libraries_featured_search, class: FeaturedSearch do
      slug { 'culibraries' }
      label { 'Libraries' }
      thumbnail_url { '/featured/partner/culibraries.png' }
      priority { 1 }
      url { "https://library.columbia.edu" }
      description { "The Libraries are at Columbia University.\n\nColumbia University is around the Libraries." }
      association :feature_category, factory: :partner_feature_category, strategy: :create
      after(:create) do |feature, _evaluator|
        create_list :featured_search_value, 1, featured_search: feature, value: 'Libraries'
      end
    end
  end
end
