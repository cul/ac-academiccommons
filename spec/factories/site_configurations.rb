FactoryBot.define do
  factory :site_configuration do
    downloads_enabled { false }
    downloads_message { "MyString" }
    deposits_enabled { false }
    alert_message_enabled { false }
    alert_message { "MyString" }
  end
end
