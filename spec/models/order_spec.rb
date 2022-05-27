require 'spec_helper'

describe 'order' do
  it 'deletes also an empty customer order' do
    pool = FactoryBot.create(:inventory_pool)
    user = FactoryBot.create(:user)
    co = FactoryBot.create(:customer_order, user: user)
    o = FactoryBot.create(:order, inventory_pool: pool, user: user, customer_order: co)
    o.delete
    expect { co.reload }.to raise_error /Record not found/
  end

  it 'inconsistent user_id with customer_orders raises an error' do
    pool = FactoryBot.create(:inventory_pool)
    user = FactoryBot.create(:user)
    user2 = FactoryBot.create(:user)
    co = FactoryBot.create(:customer_order, user: user)
    o = FactoryBot.create(:order, inventory_pool: pool, user: user, customer_order: co)
    expect { o.update(user_id: user2.id) }.to raise_error /User ID of respective customer order differs/
  end
end
