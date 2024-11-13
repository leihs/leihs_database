require 'spec_helper'

describe 'item' do
  example 'deletion is prohibited' do
    ip = FactoryBot.create(:inventory_pool)
    i = FactoryBot.create(:item, inventory_pool: ip)
    expect { i.delete }.to raise_error /Deletion is forbidden on the items table./
  end
end
