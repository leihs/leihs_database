class Delegation < Sequel::Model(:users)
  alias_method :name, :firstname

  many_to_many(:members,
               class: :User,
               left_key: :delegation_id,
               right_key: :user_id,
               join_table: :delegations_users)

  many_to_one(:responsible_user,
              key: :delegator_user_id,
              class: :User)
end

FactoryBot.define do
  factory :delegation do
    firstname { Faker::Name.unique.last_name + '-' + Faker::Name.unique.last_name }
    responsible_user { create(:user) }
    organization { Faker::Lorem.characters(number: 8) }
  end
end
