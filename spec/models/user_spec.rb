require "spec_helper"
require_relative "../../lib/leihs/constants"

describe "user" do
  example "insert into users table puts all users into all users group" do
    Group.find(id: Leihs::Constants::ALL_USERS_GROUP_UUID)

    user_1 = FactoryBot.create(:user)

    expect(
      GroupUser.find(user_id: user_1.id,
        group_id: Leihs::Constants::ALL_USERS_GROUP_UUID)
    ).to be
    GroupUser.find(user_id: user_1.id,
      group_id: Leihs::Constants::ALL_USERS_GROUP_UUID)
      .delete

    user_2 = FactoryBot.create(:user)

    FactoryBot.create(:user, delegator_user_id: user_2.id)

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

  example "prevent case insensitive leihs- organization prefix" do
    %w[lEiHs-foo LEIHS-bar leihs-].each do |org|
      expect { FactoryBot.create(:user, organization: org) }
        .to raise_error Sequel::CheckConstraintViolation
      expect(User.find(organization: org)).not_to be
    end
  end

  example "allowed organization prefixes" do
    %w[foo-leihs bar-leihs-baz].each do |org|
      expect { FactoryBot.create(:user, organization: org) }
        .not_to raise_error
      expect(User.find(organization: org)).to be
    end
  end
end
