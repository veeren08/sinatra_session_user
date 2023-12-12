FactoryBot.define do
  factory :user do
    email { 'test@example.com' }
    password_digest { 'password' }
  end
end