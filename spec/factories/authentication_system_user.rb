class AuthenticationSystemUser < Sequel::Model(:authentication_systems_users)
  many_to_one :user
  many_to_one :authentication_system
end

FactoryBot.define do
  factory :authentication_system_user do
    user
    authentication_system
    data { Faker::Crypto.md5 }
  end
end
