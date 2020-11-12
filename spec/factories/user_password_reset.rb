class UserPasswordReset < Sequel::Model(:user_password_resets)
  many_to_one :user
end

FactoryBot.define do
  factory :user_password_reset do
    user
    used_user_param { user.login or user.email }
    token { Faker::Crypto.md5.upcase }
    valid_until { DateTime.now + 1.hour }
  end
end
