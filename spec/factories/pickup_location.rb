class PickupLocation < Sequel::Model(:pickup_locations)
end

FactoryBot.define do
  factory :pickup_location do
    inventory_pool_id { InventoryPool.all.sample.id }
    name { Faker::Company.name }
    active { true }
  end
end
