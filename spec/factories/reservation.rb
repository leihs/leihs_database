class Reservation < Sequel::Model
  many_to_one(:leihs_model, key: :model_id)
  many_to_one(:order)
  many_to_one(:inventory_pool)
  many_to_one(:user)
  many_to_one(:contract)
  many_to_one(:item)
end

FactoryBot.define do
  factory :reservation do
    user_id { User.all.sample.id }
    inventory_pool_id { InventoryPool.all.sample.id }
    leihs_model
    status { "approved" }
    start_date { Date.tomorrow.to_s }
    end_date { (Date.tomorrow + 1.day).to_s }
    created_at { Time.now }
    updated_at { Time.now }
  end
end
