class InventoryPool < Sequel::Model(:inventory_pools)
end

FactoryBot.define do
  factory :inventory_pool do
    name { Faker::Company.name }
    email { Faker::Internet.email }

    after :build do |inventory_pool|
      inventory_pool.shortname = inventory_pool.name.split(" ").map(&:first).join
    end
  end
end
