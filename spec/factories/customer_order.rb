class CustomerOrder < Sequel::Model
  many_to_one(:user)
  one_to_many(:orders, key: :customer_order_id)
end

FactoryBot.define do
  factory :customer_order do
    user
    purpose { Faker::Lorem.sentence }
    title { purpose }
  end
end
