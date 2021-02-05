require 'spec_helper'
require_relative '../../lib/leihs/constants'

describe 'user' do
  example 'insert into users table puts all users into all users group' do
    all_users_group = Group.find(id: Leihs::Constants::ALL_USERS_GROUP_UUID)

    user_1 = FactoryBot.create(:user)

    expect(
      GroupUser.find(user_id: user_1.id,
                     group_id: Leihs::Constants::ALL_USERS_GROUP_UUID)
    ).to be
    GroupUser.find(user_id: user_1.id,
                   group_id: Leihs::Constants::ALL_USERS_GROUP_UUID)
      .delete

    user_2 = FactoryBot.create(:user)

    delegation = FactoryBot.create(:user, delegator_user_id: user_2.id)

    user_3 = FactoryBot.create(:user)

    expect(GroupUser.count).to eq 3
    expect(
      GroupUser.find(user_id: user_1.id,
                     group_id: Leihs::Constants::ALL_USERS_GROUP_UUID)
    ).to be
    expect(
      GroupUser.find(user_id: user_2.id,
                     group_id: Leihs::Constants::ALL_USERS_GROUP_UUID)
    ).to be
    expect(
      GroupUser.find(user_id: user_3.id,
                     group_id: Leihs::Constants::ALL_USERS_GROUP_UUID)
    ).to be
  end
end
