class User < Sequel::Model(:users)
end

FactoryBot.define do
  factory :user do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    email { "#{firstname}.#{lastname}@#{Faker::Internet.domain_name}" }
  end
end
