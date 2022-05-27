require 'spec_helper'

describe 'customer order' do
  it 'inconsistent user_id with some order raises an error' do
    pool = FactoryBot.create(:inventory_pool)
    pool2 = FactoryBot.create(:inventory_pool)
    user = FactoryBot.create(:user)
    user2 = FactoryBot.create(:user)
    co = FactoryBot.create(:customer_order, user: user)
    o = FactoryBot.create(:order, inventory_pool: pool, user: user, customer_order: co)
    o2 = FactoryBot.create(:order, inventory_pool: pool2, user: user, customer_order: co)
    expect { co.update(user_id: user2.id) }.to raise_error /User ID of some of the contained orders differs/
  end
end
