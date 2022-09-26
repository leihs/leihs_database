require 'spec_helper'

describe 'building' do
  it 'creates a general room automatically on insert' do
    building = FactoryBot.create(:building)
    expect(Room.find(general: true, building: building)).to be
  end
end

