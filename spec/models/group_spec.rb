require 'spec_helper'
require_relative '../../lib/leihs/constants'

describe 'group' do
  example 'deleting all users group is not possible' do
    all_users_group = Group.find(id: Leihs::Constants::ALL_USERS_GROUP_UUID)
    expect { all_users_group.delete }.to raise_error Sequel::DatabaseError
    expect(Group.find(id: Leihs::Constants::ALL_USERS_GROUP_UUID)).to be
  end
end
