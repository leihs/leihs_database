class Order < Sequel::Model(:orders)
  many_to_one(:user)
  many_to_one(:inventory_pool)
  many_to_one(:customer_order)
  one_to_many(:reservations, key: :order_id)
end

FactoryBot.define do
  factory :order do
    customer_order
    user
    inventory_pool
    state { 'submitted' }
    purpose { Faker::Lorem.sentence }
  end
end
