class Holiday < Sequel::Model
  many_to_one :inventory_pool
end

FactoryBot.define do
  factory :holiday do
    name { Faker::Name.name }
    start_date { Faker::Date.forward(days: 23) }
    end_date { start_date + 1 }
  end
end
