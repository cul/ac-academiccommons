# frozen_string_literal: true
FactoryBot.define do
  factory :feature_category do
    factory :partner_feature_category do
      field_name { 'department_ssim' }
      label { 'partner' }
      thumbnail_url { 'featured/partner.png' }
    end
  end
end
