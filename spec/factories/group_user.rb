class GroupUser < Sequel::Model(:groups_users)
end

FactoryBot.define do
  factory :group_user do
  end
end
