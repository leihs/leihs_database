class User < Sequel::Model
  attr_accessor :password
end

class AuthenticationSystemUser < Sequel::Model(:authentication_systems_users)
end

FactoryBot.define do
  factory :user do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.unique.last_name }
    email { firstname + '.' + lastname + '@' + Faker::Internet.domain_name }
    password { Faker::Internet.password() }
    is_admin { false }
    protected { rand < 0.5 }

    after(:create) do |user|
      pw_hash  =  database["SELECT crypt(#{database.literal(user.password)}, " \
                           "gen_salt('bf')) AS pw_hash"].first[:pw_hash]
      database[:authentication_systems_users].insert(
        user_id: user.id,
        authentication_system_id: 'password',
        data: pw_hash)
    end

    factory :admin do
      is_admin { true }
    end

    factory :system_admin do
      is_admin { true }
      after(:create) do |user|
        database[:system_admin_users].insert user_id: user.id
      end
    end

  end
end
