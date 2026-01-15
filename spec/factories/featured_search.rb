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
      association :feature_category, factory: :partner_feature_category
      after(:build) do |feature, _evaluator|
        # build a :featured_search_value factory for nested attribute
        feature.featured_search_values.build(value: 'Libraries')
      end
    end
  end
end
