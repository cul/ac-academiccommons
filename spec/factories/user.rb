FactoryBot.define do
  factory :user do
    uid 'tu123'
    first_name 'Test'
    last_name 'User'
    email 'tu123@columbia.edu'
  end

  factory :admin, class: User do
    uid 'ta123'
    first_name 'Test'
    last_name 'Admin'
    email 'ta123@columbia.edu'
    role User::ADMIN
  end
end
