# frozen_string_literal: true

FactoryBot.define do
  factory :site_configuration do
    downloads_enabled { true }
    downloads_message { 'Test downloads message' }
    deposits_enabled { true }
    alert_message { 'Test alert message' }
    singleton_guard { 0 }
  end
end
