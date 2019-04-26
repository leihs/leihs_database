class UserPasswordReset < Sequel::Model(:user_password_resets)
  many_to_one :user
end

FactoryBot.define do
  factory :user_password_reset do
    user
    token { Faker::Crypto.md5 }
    expired_at { DateTime.now + 1.hour }
  end
end
