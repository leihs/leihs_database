require 'spec_helper'

describe 'user' do
  context 'create' do
    example 'trigger insert into access rights' do
      FactoryBot.create(:access_right)

      ip_without_automatic_access = FactoryBot.create(:inventory_pool)
      ip_with_automatic_access = FactoryBot.create(:inventory_pool,
                                                   automatic_access: true)

      user = FactoryBot.create(:user)

      expect(AccessRight.count).to eq(2)
      expect(
        AccessRight.find(user: user,
                         inventory_pool: ip_with_automatic_access,
                         role: 'customer')
      ).to be
    end
  end
end
