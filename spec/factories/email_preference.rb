# frozen_string_literal: true

FactoryBot.define do
  factory :email_preference, class: 'EmailPreference' do
    uni { 'tu123' }
    email { 'tu123@example.org' }
    unsubscribe { false }
  end
end
