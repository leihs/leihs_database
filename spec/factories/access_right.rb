class AccessRight < Sequel::Model(:access_rights)
  many_to_one :user
  many_to_one :inventory_pool
end

FactoryBot.define do
  factory :access_right do
    inventory_pool
    role { 'customer' }
    user
  end
end
