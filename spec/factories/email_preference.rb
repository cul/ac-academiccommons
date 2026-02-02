# frozen_string_literal: true

FactoryBot.define do
  factory :email_preference do
    id { 1 }
    uni { 'testuser' }
    unsubscribe { false }
    email { 'testuser@example.com' }
  end
end
