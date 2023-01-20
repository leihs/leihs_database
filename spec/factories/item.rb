class Item < Sequel::Model
  many_to_one(:leihs_model, key: :model_id)
  many_to_one(:inventory_pool)
  many_to_one(:owner, class: :InventoryPool, key: :owner_id)
  many_to_one(:room)
  one_to_many(:reservations)
end

FactoryBot.define do
  factory :item do
    inventory_code { Faker::Alphanumeric.alphanumeric(number: 10) }
    leihs_model
    association :owner, factory: :inventory_pool
    association :responsible, factory: :inventory_pool
    room

    is_borrowable { true }

    created_at { DateTime.now }
    updated_at { DateTime.now }
  end
end
