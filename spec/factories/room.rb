class Room < Sequel::Model
  many_to_one :building
end

FactoryBot.define do
  factory :room do
    name { "#{Faker::House.room} #{Faker::Lorem.characters(number: 8)}" }
    building
    general { false }
  end
end
