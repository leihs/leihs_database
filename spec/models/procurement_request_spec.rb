require 'spec_helper'

describe 'procurement request' do
  it 'deletes also an empty customer order' do
    pool = FactoryBot.create(:inventory_pool)
    user = FactoryBot.create(:user)
    co = FactoryBot.create(:customer_order, user: user)
    o = FactoryBot.create(:order, inventory_pool: pool, user: user, customer_order: co)
    o.delete
    expect { co.reload }.to raise_error /Record not found/
  end
end
