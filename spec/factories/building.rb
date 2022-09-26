class Building < Sequel::Model
  one_to_many(:rooms)
end

FactoryBot.define do
  factory :building do
    name { Faker::Address.street_address }
  end
end
