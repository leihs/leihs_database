class InventoryPool < Sequel::Model(:inventory_pools)
  def after_create
    Workday.create(inventory_pool_id: self.id)
    super
  end
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
